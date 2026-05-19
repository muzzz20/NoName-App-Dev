/// Typed failure class to ensure raw exceptions don't reach the UI.
class CampaignFailure implements Exception {
  final String message;

  const CampaignFailure(this.message);

  @override
  String toString() => message;
}
