import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../models/donation_failure.dart';
import '../services/donation_service.dart';
import '../widgets/amount_chip_selector.dart';
import '../widgets/payment_form.dart';

class DonationFlowScreen extends StatefulWidget {
  const DonationFlowScreen({super.key});

  @override
  State<DonationFlowScreen> createState() => _DonationFlowScreenState();
}

class _DonationFlowScreenState extends State<DonationFlowScreen> {
  final _service = DonationService();
  final _formKey = GlobalKey<FormState>();
  
  double _selectedAmount = 10;
  bool _isCustomAmount = false;
  bool _isLoading = false;
  
  final _customAmountController = TextEditingController();
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  void _processPayment() async {
    if (_isCustomAmount) {
      final customVal = double.tryParse(_customAmountController.text) ?? 0;
      if (customVal < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum custom donation is RM 1.00')),
        );
        return;
      }
      _selectedAmount = customVal;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final receipt = await _service.processDonation(
        amount: _selectedAmount,
        cardName: _nameController.text,
        cardNumber: _cardController.text,
      );
      
      if (!mounted) return;
      context.push(AppRoutes.donationReceipt, extra: receipt);
    } on DonationFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Donate', style: TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AmountChipSelector(
              selectedAmount: _selectedAmount,
              isCustom: _isCustomAmount,
              onAmountChanged: (val) {
                setState(() {
                  _isCustomAmount = false;
                  _selectedAmount = val;
                });
              },
              onCustomSelected: () {
                setState(() => _isCustomAmount = true);
              },
            ),
            if (_isCustomAmount) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Custom Amount (RM)',
                  prefixText: 'RM ',
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            PaymentForm(
              formKey: _formKey,
              nameController: _nameController,
              cardController: _cardController,
              expiryController: _expiryController,
              cvvController: _cvvController,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.onPrimary)
                  : const Text('Donate Now', style: TextStyle(color: AppColors.onPrimary, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
