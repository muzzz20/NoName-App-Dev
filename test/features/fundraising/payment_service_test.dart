// Unit tests for PaymentService deterministic behavior (NAD-21 / NAD-34).
// Pure-function tests — no network, no Firestore. PaymentService is a
// pure simulation in Sprint 2, so the trigger table in its dartdoc is
// the contract these tests pin down.

import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/fundraising/services/payment_service.dart';

void main() {
  late PaymentService service;

  setUp(() {
    service = PaymentService();
  });

  group('PaymentService input validation', () {
    test('throws PaymentFailure on zero amount', () async {
      await expectLater(
        service.processPayment(
          amountSen: 0,
          donorId: 'u1',
          campaignId: 'c1',
        ),
        throwsA(isA<PaymentFailure>()),
      );
    });
    test('throws PaymentFailure on negative amount', () async {
      await expectLater(
        service.processPayment(
          amountSen: -100,
          donorId: 'u1',
          campaignId: 'c1',
        ),
        throwsA(isA<PaymentFailure>()),
      );
    });
  });

  group('PaymentService deterministic failure triggers', () {
    test('amount ending in 08 returns cardDeclined', () async {
      final result = await service.processPayment(
        amountSen: 10008,
        donorId: 'u1',
        campaignId: 'c1',
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureCode, PaymentFailureCode.cardDeclined);
      expect(result.message, contains('declined'));
      expect(result.transactionId, isNull);
    });

    test('amount ending in 09 returns insufficientFunds', () async {
      final result = await service.processPayment(
        amountSen: 5009,
        donorId: 'u1',
        campaignId: 'c1',
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureCode, PaymentFailureCode.insufficientFunds);
      expect(result.message, contains('Insufficient'));
    });

    test('amount ending in 77 returns expiredCard', () async {
      final result = await service.processPayment(
        amountSen: 1077,
        donorId: 'u1',
        campaignId: 'c1',
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureCode, PaymentFailureCode.expiredCard);
    });
  });

  group('PaymentService success path', () {
    test('amount ending in 00 succeeds with transactionId', () async {
      final result = await service.processPayment(
        amountSen: 10000,
        donorId: 'u1',
        campaignId: 'c1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.transactionId, isNotNull);
      expect(result.failureCode, isNull);
      expect(result.transactionId, startsWith('sim_tx_'));
    });

    test('transactionId format is sim_tx_<ms>_<6hex>', () async {
      final result = await service.processPayment(
        amountSen: 2500,
        donorId: 'u1',
        campaignId: 'c1',
      );
      expect(result.transactionId, isNotNull);
      final parts = result.transactionId!.split('_');
      expect(parts.length, 4); // sim, tx, ms, hex
      expect(parts[0], 'sim');
      expect(parts[1], 'tx');
      expect(int.tryParse(parts[2]), isNotNull); // timestamp
      expect(parts[3].length, 6);
      expect(int.tryParse(parts[3], radix: 16), isNotNull); // hex
    });

    test('arbitrary non-trigger amounts succeed', () async {
      for (final amount in [1, 99, 123, 4567, 99901]) {
        final result = await service.processPayment(
          amountSen: amount,
          donorId: 'u1',
          campaignId: 'c1',
        );
        expect(
          result.isSuccess,
          isTrue,
          reason: 'amount $amount should succeed (last 2 digits = '
              '${amount % 100})',
        );
      }
    });
  });
}
