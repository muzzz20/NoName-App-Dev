import 'dart:math';

/// Payment gateway integration. NAD-21.
///
/// **Sprint 2 is simulation-only** — no real gateway HTTP calls. The
/// surface area matches what a real Stripe / Billplz / ToyyibPay SDK
/// would expose, so Sprint 4 can swap the simulated body with real
/// gateway calls **without changing callers**.
///
/// Why simulation:
/// - Academic project; PCI / production credentials out of scope.
/// - QA needs deterministic failure paths to exercise the donation
///   `status = 'failed'` branch in NAD-26 / NAD-34.
/// - .env retains placeholder keys (`STRIPE_PUBLISHABLE_KEY`,
///   `BILLPLZ_API_KEY` — already in `.env.example`) so the real swap
///   is config-only, not code rewrite.
///
/// Deterministic test trigger (so QA can write test cases against this):
/// - `amount` last 2 digits in sen control the outcome.
///   * `...08` → `cardDeclined`
///   * `...09` → `insufficientFunds`
///   * `...77` → `expiredCard`
///   * any other → success
///   * `amount <= 0` → throws [PaymentFailure] before simulation
///
/// Examples QA can use on the Submit Donation screen:
/// - RM 100.00 (10000 sen, ends 00) → success
/// - RM 100.08 (10008 sen) → `cardDeclined`
/// - RM 100.09 (10009 sen) → `insufficientFunds`
/// - RM 100.77 (10077 sen) → `expiredCard`
class PaymentService {
  PaymentService({Random? random})
      : _random = random ?? Random.secure();

  final Random _random;

  /// Simulate a payment authorization + capture.
  ///
  /// Returns a [PaymentResult]. Successful results carry a generated
  /// `transactionId`. Failed results carry a [PaymentFailureCode] and a
  /// user-friendly `message` suitable for surfacing in the UI.
  ///
  /// `amountSen` is the amount to charge in MYR sen (1 RM = 100 sen).
  /// `donorId` is the Firebase Auth uid of the donor (passed through
  /// to the transaction record for traceability).
  /// `campaignId` is the campaign being donated to.
  Future<PaymentResult> processPayment({
    required int amountSen,
    required String donorId,
    required String campaignId,
  }) async {
    if (amountSen <= 0) {
      throw const PaymentFailure(
        'Donation amount must be greater than zero.',
      );
    }

    // Simulate network round-trip latency (200–600 ms).
    await Future<void>.delayed(
      Duration(milliseconds: 200 + _random.nextInt(400)),
    );

    final trigger = amountSen % 100;
    if (trigger == 8) {
      return PaymentResult.failure(
        code: PaymentFailureCode.cardDeclined,
        message: 'Your card was declined. Try a different payment method.',
      );
    }
    if (trigger == 9) {
      return PaymentResult.failure(
        code: PaymentFailureCode.insufficientFunds,
        message: 'Insufficient funds. Reduce the amount or try another card.',
      );
    }
    if (trigger == 77) {
      return PaymentResult.failure(
        code: PaymentFailureCode.expiredCard,
        message: 'Your card has expired. Please update your payment method.',
      );
    }

    final transactionId = _generateTransactionId();
    return PaymentResult.success(transactionId: transactionId);
  }

  /// Format: `sim_tx_<timestamp_ms>_<6-hex>`.
  /// Sprint 4 real gateway will return its own IDs (e.g. `pi_xxx` for
  /// Stripe payment intents); callers must treat this field as opaque.
  String _generateTransactionId() {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'sim_tx_${ts}_$suffix';
  }
}

/// Outcome of a payment attempt. Discriminated union — exactly one of
/// `transactionId` or `failureCode` is non-null.
class PaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final PaymentFailureCode? failureCode;
  final String? message;

  const PaymentResult._({
    required this.isSuccess,
    this.transactionId,
    this.failureCode,
    this.message,
  });

  factory PaymentResult.success({required String transactionId}) {
    return PaymentResult._(
      isSuccess: true,
      transactionId: transactionId,
    );
  }

  factory PaymentResult.failure({
    required PaymentFailureCode code,
    required String message,
  }) {
    return PaymentResult._(
      isSuccess: false,
      failureCode: code,
      message: message,
    );
  }
}

/// Clear, taxonomically-stable failure codes. UI can decide what to do
/// per code (retry button, "use a different card", etc.). Names mirror
/// what real gateways (Stripe / Billplz) commonly return.
enum PaymentFailureCode {
  cardDeclined,
  insufficientFunds,
  expiredCard,
  networkError, // Reserved for Sprint 4 real-gateway implementation.
  unknown; // Catch-all for Sprint 4 swap.

  String get storageKey => name;
}

/// Friendly error for caller validation failures (e.g. amount <= 0).
/// Distinct from [PaymentResult.failure] which represents a
/// gateway-side decline.
class PaymentFailure implements Exception {
  final String message;
  const PaymentFailure(this.message);

  @override
  String toString() => message;
}
