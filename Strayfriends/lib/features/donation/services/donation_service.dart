import '../models/donation_failure.dart';
import '../models/receipt_model.dart';

// STUB: Replace with real impl when NAD-26 + NAD-21 merge
class DonationService {
  /// Simulates a sandbox payment gateway process.
  Future<ReceiptModel> processDonation({
    required double amount,
    required String cardName,
    required String cardNumber,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulate validation error scenario
    if (amount <= 0) {
      throw const DonationFailure('Amount must be greater than zero.');
    }

    return ReceiptModel(
      donorName: cardName,
      donationId: 'DON-${DateTime.now().millisecondsSinceEpoch}',
      campaignName: 'Strayfriends Welfare Fund',
      amount: amount,
      date: DateTime.now(),
      transactionId: 'TXN-987654321',
    );
  }
}
