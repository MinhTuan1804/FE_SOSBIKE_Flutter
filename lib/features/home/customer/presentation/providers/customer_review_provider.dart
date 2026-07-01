import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/repositories/customer_review_repository.dart';

class CustomerReviewProvider extends ChangeNotifier {
  CustomerReviewProvider(this._repository);

  final CustomerReviewRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('CustomerReviewProvider.submitReview: $e');
      }
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
