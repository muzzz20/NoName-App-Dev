class ReceiptModel {
  final String donorName;
  final String donationId;
  final String campaignName;
  final double amount;
  final DateTime date;
  final String transactionId;

  /// Creates a typed model to hold donation receipt details.
  const ReceiptModel({
    required this.donorName,
    required this.donationId,
    required this.campaignName,
    required this.amount,
    required this.date,
    required this.transactionId,
  });
}
