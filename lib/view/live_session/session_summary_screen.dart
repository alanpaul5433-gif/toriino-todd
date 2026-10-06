import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/ai/transcript_model.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String sessionId;
  final TranscriptModel transcript;
  final String subjectArea;

  const SessionSummaryScreen({
    required this.sessionId,
    required this.transcript,
    this.subjectArea = 'general',
    super.key,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final _repo = SessionRepo();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    try {
      // Save transcript first
      await _repo.saveTranscript(widget.sessionId, widget.transcript.toJson());

      final plainText = widget.transcript.toPlainText();
      if (plainText.trim().isEmpty) {
        setState(() { _loading = false; _error = 'No transcript available for this session.'; });
        return;
      }

      final result = await _repo.generateSummary(
        widget.sessionId,
        plainText,
        subjectArea: widget.subjectArea,
      );
      setState(() { _summary = result; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session Summary',
                      style: GoogleFonts.rethinkSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text('Done', style: GoogleFonts.dmSans(color: AppColor.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text('Generating AI summary...', style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    )
                  : _error != null
                      ? _errorView()
                      : _summaryView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryView() {
    final summary = _summary!;
    final actionItems = List<String>.from(summary['actionItems'] ?? []);
    final keyTopics = List<String>.from(summary['keyTopics'] ?? []);
    final insights = List<String>.from(summary['insights'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            icon: Icons.auto_awesome,
            title: 'Summary',
            child: Text(
              summary['summary'] ?? '',
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          if (actionItems.isNotEmpty)
            _sectionCard(
              icon: Icons.check_circle_outline,
              title: 'Action Items',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: actionItems.map((item) => _bulletItem(item)).toList(),
              ),
            ),
          const SizedBox(height: 16),
          if (keyTopics.isNotEmpty)
            _sectionCard(
              icon: Icons.topic_outlined,
              title: 'Key Topics',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keyTopics.map((t) => _chip(t)).toList(),
              ),
            ),
          const SizedBox(height: 16),
          if (insights.isNotEmpty)
            _sectionCard(
              icon: Icons.lightbulb_outline,
              title: 'Insights',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insights.map((i) => _bulletItem(i)).toList(),
              ),
            ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '${widget.transcript.segments.length} transcript segments · ${_durationLabel(widget.transcript.totalDuration)}',
              style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColor.red, size: 16),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: Colors.white54),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColor.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.red.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.red),
              onPressed: () { setState(() { _loading = true; _error = null; }); _generateSummary(); },
              child: Text('Retry', style: GoogleFonts.dmSans(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
