/// Typed failure class to ensure raw exceptions don't reach the UI.
class DonationFailure implements Exception {
  final String message;

  const DonationFailure(this.message);

  @override
  String toString() => message;
}
