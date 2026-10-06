import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/services/analytics_service.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/agora_service.dart';
import 'package:toriino_todd/services/session_intelligence_service.dart';
import 'package:toriino_todd/view/live_session/session_summary_screen.dart';

class LiveSessionScreen extends StatefulWidget {
  final String sessionId;
  final bool isMentor;
  final String subjectArea;

  const LiveSessionScreen({
    required this.sessionId,
    this.isMentor = true,
    this.subjectArea = 'general',
    super.key,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  final _repo = SessionRepo();
  late final SessionIntelligenceService _intelligence;

  bool _joined = false;
  bool _loading = true;
  String? _error;

  int? _remoteUid;
  bool _micMuted = false;
  bool _camOff = false;
  bool _recordingEnabled = false;
  bool _recordingActive = false;

  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _agoraToken;

  @override
  void initState() {
    super.initState();
    _intelligence = SessionIntelligenceService(
      sessionId: widget.sessionId,
      subjectArea: widget.subjectArea,
    );
    if (widget.isMentor) {
      _showConsentDialog();
    } else {
      _start();
    }
  }

  Future<void> _showConsentDialog() async {
    final consent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Session Recording', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
          'Would you like to enable AI-powered session recording?\n\n'
          'This records the session, generates a transcript, and creates an AI summary with action items and key insights.\n\n'
          'Participants will be notified that recording is active.',
          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Skip', style: GoogleFonts.dmSans(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Enable Recording', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    setState(() => _recordingEnabled = consent ?? false);
    _start();
  }

  Future<void> _start() async {
    try {
      final data = await _repo.fetchAgoraToken(
        widget.sessionId,
        role: widget.isMentor ? 'publisher' : 'subscriber',
      );
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Agora token missing from server response');
      }
      _agoraToken = token;

      AgoraService.registerEventHandlers(
        onUserJoined: (conn, uid, elapsed) {
          if (mounted) setState(() => _remoteUid = uid);
        },
        onUserOffline: (conn, uid, reason) {
          if (mounted) setState(() => _remoteUid = null);
        },
        onError: (code, msg) {
          if (mounted) setState(() => _error = 'Agora error: $msg');
        },
      );

      await AgoraService.joinChannel(
        token: token,
        channelName: widget.sessionId,
        uid: 0,
        isBroadcaster: widget.isMentor,
      );

      if (mounted) {
        setState(() {
          _joined = true;
          _loading = false;
        });
        AnalyticsService.logSessionJoin(
          sessionId: widget.sessionId,
          isMentor: widget.isMentor,
        );
        _intelligence.onSessionStart();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsedSeconds++);
        });
        if (_recordingEnabled && widget.isMentor) {
          _startCloudRecording();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _startCloudRecording() async {
    try {
      await _repo.startRecording(widget.sessionId, agoraToken: _agoraToken ?? '');
      if (mounted) setState(() => _recordingActive = true);
    } catch (_) { /* recording is best-effort */ }
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    final transcript = _intelligence.onSessionEnd();

    if (_recordingActive) {
      try { await _repo.stopRecording(widget.sessionId); } catch (_) {}
      setState(() => _recordingActive = false);
    }

    await AgoraService.leaveChannel();

    if (!mounted) return;

    // If mentor recorded, navigate to summary screen; otherwise just pop
    if (widget.isMentor && _intelligence.hasTranscript) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            sessionId: widget.sessionId,
            transcript: transcript,
            subjectArea: widget.subjectArea,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  String get _timeLabel {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    AgoraService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_joined && _remoteUid != null && AgoraService.engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: AgoraService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.sessionId),
              ),
            )
          else
            _waitingPlaceholder(),

          // Local video (picture-in-picture, top-right)
          if (_joined && !_camOff && AgoraService.engine != null)
            Positioned(
              top: 52,
              right: 16,
              width: 110,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: AgoraService.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // Timer badge + recording indicator (top-left)
          if (_joined)
            Positioned(
              top: 52,
              left: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _timeLabel,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_recordingActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.white, size: 8),
                          const SizedBox(width: 4),
                          Text('REC', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (_error != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Go Back', style: GoogleFonts.dmSans(color: AppColor.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Control bar (bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlBtn(
                  icon: _micMuted ? Icons.mic_off : Icons.mic,
                  label: _micMuted ? 'Unmute' : 'Mute',
                  onTap: () {
                    setState(() => _micMuted = !_micMuted);
                    AgoraService.muteLocalAudio(_micMuted);
                  },
                ),
                const SizedBox(width: 20),
                // End call button (larger, red)
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 20),
                _controlBtn(
                  icon: _camOff ? Icons.videocam_off : Icons.videocam,
                  label: _camOff ? 'Cam On' : 'Cam Off',
                  onTap: () {
                    setState(() => _camOff = !_camOff);
                    AgoraService.muteLocalVideo(_camOff);
                  },
                ),
              ],
            ),
          ),

          // Switch camera (top-right below PiP)
          if (_joined && !_camOff)
            Positioned(
              top: 224,
              right: 16,
              child: GestureDetector(
                onTap: AgoraService.switchCamera,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _waitingPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF2A2A4E),
              child: Icon(Icons.person, color: Colors.white54, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              _loading ? 'Connecting...' : 'Waiting for participant to join...',
              style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
