import 'package:flutter/material.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/course_enroll_flow.dart';
import 'package:video_player/video_player.dart';

/// Plays a video.
///
/// * Private lesson video: pass [courseId] + [lessonId]. A fresh pre-signed
///   URL (valid 300 s) is fetched from
///   GET /courses/{courseId}/lessons/{lessonId}/media right before playing,
///   and re-fetched once if the player errors (e.g. the URL expired).
///   A 402 shows "Enroll in this course to watch" with the enroll/purchase
///   action (needs [course]).
/// * Public / legacy video (intro videos, old lessons with a plain
///   `videoUrl`): pass [videoUrl] only.
class LessonVideoView extends StatefulWidget {
  final String? videoUrl;
  final String title;
  final String? courseId;
  final String? lessonId;
  final CourseModel? course;

  const LessonVideoView({
    super.key,
    this.videoUrl,
    required this.title,
    this.courseId,
    this.lessonId,
    this.course,
  });

  @override
  State<LessonVideoView> createState() => _LessonVideoViewState();
}

class _LessonVideoViewState extends State<LessonVideoView> {
  final _repo = CourseRepo();
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _paymentRequired = false;
  bool _refetchedAfterError = false;
  bool _recovering = false;
  String? _error;

  bool get _usesMediaEndpoint =>
      (widget.courseId ?? '').isNotEmpty && (widget.lessonId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Returns the URL to play: a freshly fetched pre-signed URL for private
  /// lessons, or the given public/legacy URL.
  Future<String> _resolveUrl() async {
    if (_usesMediaEndpoint) {
      final res =
          await _repo.getLessonMedia(widget.courseId!, widget.lessonId!);
      final media = LessonMediaModel.fromJson(
          res is Map<String, dynamic> ? res : <String, dynamic>{});
      final url = media.videoUrl;
      if (url == null) throw Exception('This lesson has no video.');
      return url;
    }
    final url = widget.videoUrl ?? '';
    if (url.isEmpty) throw Exception('No video available.');
    return url;
  }

  Future<void> _load({Duration? resumeAt}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _paymentRequired = false;
    });
    await _disposeController();
    var urlResolved = false;
    try {
      final url = await _resolveUrl();
      urlResolved = true;
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      if (resumeAt != null) await controller.seekTo(resumeAt);
      if (!mounted) {
        await _disposeController();
        return;
      }
      controller.addListener(_onPlayerUpdate);
      setState(() => _loading = false);
      controller.play();
      _recovering = false;
    } on PaymentRequiredException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _paymentRequired = true;
      });
    } catch (e) {
      // The player could not open the URL (e.g. it expired): fetch a fresh
      // pre-signed URL once and try again.
      if (urlResolved && _usesMediaEndpoint && !_refetchedAfterError) {
        _refetchedAfterError = true;
        return _load(resumeAt: resumeAt);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _recovering = false;
        _error = Utils.errorMessage(e);
      });
    }
  }

  /// Mid-playback errors (typically the pre-signed URL expired while
  /// buffering): fetch a new URL once and resume where we were.
  void _onPlayerUpdate() {
    final c = _controller;
    if (c == null || !c.value.hasError || _recovering) return;
    if (_usesMediaEndpoint && !_refetchedAfterError) {
      _recovering = true;
      _refetchedAfterError = true;
      _load(resumeAt: c.value.position);
    } else if (mounted) {
      setState(() => _error = c.value.errorDescription ?? 'Playback failed');
    }
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_onPlayerUpdate);
      await c.dispose();
    }
  }

  void _retry() {
    _refetchedAfterError = false;
    _load();
  }

  Future<void> _enroll() async {
    final enrolled = await showEnrollRequiredDialog(context, widget.course);
    if (enrolled && mounted) _retry();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Widget _paymentRequiredView() {
    final course = widget.course;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Enroll in this course to watch',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (course != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _enroll,
              child: Text(
                (course.price ?? 0) > 0 ? 'Purchase' : 'Enroll',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _retry,
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    Widget body;
    if (_paymentRequired) {
      body = _paymentRequiredView();
    } else if (_error != null) {
      body = _errorView();
    } else if (_loading || controller == null) {
      body = const CircularProgressIndicator(color: Colors.white);
    } else {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          const SizedBox(height: 16),
          _VideoControls(controller: controller),
        ],
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: body),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.controller.value.isPlaying;
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      playing
                          ? widget.controller.pause()
                          : widget.controller.play();
                    },
                  ),
                ],
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
