import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// Requests the native store review prompt at a delight moment.
///
/// Call [maybeRequestReview] after a positive event (lesson completed, a
/// successful scan, a multi-day streak). The OS throttles how often the prompt
/// actually appears, so it's safe to call at natural high points — but do NOT
/// gate functionality on it and do NOT spam it.
class ReviewService {
  ReviewService([InAppReview? inAppReview])
      : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  Future<void> maybeRequestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('[ReviewService] requestReview failed: $e');
    }
  }
}

final Provider<ReviewService> reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());
