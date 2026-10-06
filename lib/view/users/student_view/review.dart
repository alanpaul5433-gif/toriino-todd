import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/repository/review_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Helper: opens the submit-review bottom sheet
// ---------------------------------------------------------------------------
void showSubmitReviewSheet(
  BuildContext context, {
  required String targetId,
  required String targetType,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        SubmitReviewSheet(targetId: targetId, targetType: targetType),
  );
}

// ---------------------------------------------------------------------------
// ReviewView – loads real reviews from API
// ---------------------------------------------------------------------------
class ReviewView extends StatefulWidget {
  final String targetId;
  final String targetType; // 'course' or 'mentor'

  const ReviewView({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _reviews = [];
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ReviewRepo().getReviews(widget.targetId);
      List<dynamic> reviews = [];
      double avg = 0;
      if (result is Map) {
        reviews = (result['reviews'] as List?) ?? [];
        avg = ((result['averageRating'] ?? result['average_rating'] ?? 0) as num)
            .toDouble();
      } else if (result is List) {
        reviews = result;
      }
      if (avg == 0 && reviews.isNotEmpty) {
        final total = reviews.fold<double>(0, (sum, r) {
          final rating = r['rating'];
          return sum + (rating is num ? rating.toDouble() : 0.0);
        });
        avg = total / reviews.length;
      }
      setState(() {
        _reviews = reviews;
        _averageRating = avg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      "assets/icons/Arrow - Right 3 (1).svg",
                    ),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    "Reviews",
                    style: GoogleFonts.rethinkSans(
                      fontSize: Responsive.textScaleFactor * 18,
                      color: AppColor.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // ── Rating summary (only when data is loaded) ────────────
              if (!_loading && _error == null) _buildRatingSummary(),

              // ── List ────────────────────────────────────────────────
              Flexible(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              'Error loading reviews',
                              style: TextStyle(color: AppColor.white),
                            ),
                          )
                        : _reviews.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_border,
                                        color: Colors.white38, size: 56),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reviews yet.',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white54,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: Responsive.padding(
                                    left: 0, right: 0, top: 0, bottom: 0),
                                itemCount: _reviews.length,
                                itemBuilder: (context, index) =>
                                    _buildReviewCard(_reviews[index]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rating summary widget ────────────────────────────────────────────────
  Widget _buildRatingSummary() {
    final totalCount = _reviews.length;
    final Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      final rating = r['rating'];
      final star = (rating is num ? rating.round() : 0).clamp(1, 5);
      starCounts[star] = (starCounts[star] ?? 0) + 1;
    }

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: Responsive.textScaleFactor * 72,
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Based on $totalCount Review${totalCount == 1 ? '' : 's'}",
              style: TextStyle(
                fontSize: Responsive.textScaleFactor * 12,
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Expanded(
          child: Column(
            spacing: 1,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(5, (i) {
              final star = i + 1;
              final count = starCounts[star] ?? 0;
              final fraction =
                  totalCount > 0 ? count / totalCount : 0.0;
              return Row(
                children: [
                  Flexible(
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(22),
                      backgroundColor:
                          AppColor.white.withValues(alpha: 0.4),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColor.red),
                      value: fraction,
                    ),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    '$star',
                    style: TextStyle(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Single review card ───────────────────────────────────────────────────
  Widget _buildReviewCard(dynamic review) {
    final name = (review['userName'] ??
            review['user_name'] ??
            review['name'] ??
            'User')
        .toString();
    final comment = (review['comment'] ??
            review['review'] ??
            review['text'] ??
            '')
        .toString();
    final rating = review['rating'];
    final starCount = (rating is num ? rating.round() : 0).clamp(0, 5);
    final createdAt =
        (review['createdAt'] ?? review['created_at'] ?? '').toString();

    return Padding(
      padding:
          Responsive.padding(left: 0, right: 0, top: 0.5, bottom: 0.5),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColor.white.withValues(alpha: 0.1),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppColor.red.withValues(alpha: 0.3),
                    child: Text(
                      name.isNotEmpty
                          ? name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(10),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < starCount ? Icons.star : Icons.star_border,
                        color: AppColor.red,
                        size: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(10),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(1)),
              Text(
                comment,
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return dateStr;
    }
  }
}

// ---------------------------------------------------------------------------
// SubmitReviewSheet – bottom sheet for submitting a new review
// ---------------------------------------------------------------------------
class SubmitReviewSheet extends StatefulWidget {
  final String targetId;
  final String targetType; // 'course' or 'mentor'

  const SubmitReviewSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends State<SubmitReviewSheet> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ReviewRepo().submitReview({
        'targetId': widget.targetId,
        'targetType': widget.targetType,
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to submit review. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Leave a Review',
            style: GoogleFonts.rethinkSans(
              fontSize: 20,
              color: AppColor.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Star rating
          Text(
            'Your rating',
            style: GoogleFonts.dmSans(
              color: AppColor.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColor.red,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comment field
          Text(
            'Your comment',
            style: GoogleFonts.dmSans(
              color: AppColor.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColor.white.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColor.white.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              controller: _commentController,
              style: GoogleFonts.dmSans(color: AppColor.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.dmSans(
                  color: AppColor.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          GestureDetector(
            onTap: _submitting ? null : _submit,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: _submitting
                    ? AppColor.red.withValues(alpha: 0.5)
                    : AppColor.red,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Review',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          color: AppColor.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
