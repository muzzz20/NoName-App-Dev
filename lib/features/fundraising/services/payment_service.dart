import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stripe Checkout integration. NAD-21.
///
/// **No Stripe key lives in the client.** The flow is:
///   1. Client calls the `createCheckoutSession` Cloud Function (which
///      holds the Stripe secret key) with the amount + campaign.
///   2. Function returns the Stripe-hosted checkout URL.
///   3. Client redirects the browser there (same tab on web).
///   4. User pays on Stripe's page (test card 4242 4242 4242 4242).
///   5. Stripe fires the `stripeWebhook` Cloud Function, which writes
///      the donation doc (status=success) — authoritative confirmation.
///   6. Stripe redirects back to `/receipt?session_id=...`; the receipt
///      screen streams the donation by session id until the webhook
///      lands (usually < 2s).
///
/// This means donations are ONLY ever created by a verified Stripe
/// payment — the client cannot fabricate a donation (firestore.rules
/// deny client writes to `donations`).
class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  /// Create a Stripe Checkout session and redirect the browser to it.
  /// Returns the Stripe `sessionId` so the receipt screen can correlate
  /// the donation the webhook will write.
  ///
  /// `origin` is the app origin (e.g. `Uri.base.origin`) used to build
  /// Stripe's success/cancel return URLs.
  ///
  /// Throws [PaymentFailure] with a friendly message on any error.
  Future<String> startCheckout({
    required int amountSen,
    required String campaignId,
    required String donorName,
    required String origin,
  }) async {
    if (amountSen < 500) {
      throw const PaymentFailure('Minimum donation is RM 5.00.');
    }

    final Map<String, dynamic> data;
    try {
      final callable = _functions.httpsCallable('createCheckoutSession');
      final result = await callable.call<Map<String, dynamic>>({
        'amountSen': amountSen,
        'campaignId': campaignId,
        'donorName': donorName,
        'origin': origin,
      });
      data = Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw PaymentFailure(_friendlyFunctionError(e));
    } catch (e) {
      throw PaymentFailure('Could not start payment: $e');
    }

    final url = data['url'] as String?;
    final sessionId = data['sessionId'] as String?;
    if (url == null || url.isEmpty) {
      throw const PaymentFailure('Payment provider did not return a URL.');
    }

    final launched = await launchUrl(
      Uri.parse(url),
      // Same-tab redirect on web so Stripe's success_url returns the
      // user straight back into the app.
      webOnlyWindowName: '_self',
      mode: LaunchMode.platformDefault,
    );
    if (!launched) {
      throw const PaymentFailure('Could not open the payment page.');
    }
    return sessionId ?? '';
  }

  String _friendlyFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to donate.';
      case 'invalid-argument':
        return e.message ?? 'Invalid donation details.';
      case 'failed-precondition':
        return e.message ?? 'This campaign is no longer accepting donations.';
      case 'not-found':
        return 'Campaign not found.';
      default:
        return 'Could not start payment. Please try again.';
    }
  }
}

/// Friendly payment error suitable for surfacing in the UI.
class PaymentFailure implements Exception {
  final String message;
  const PaymentFailure(this.message);

  @override
  String toString() => message;
}
