import 'package:flutter/material.dart';

class PaymentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cardController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;

  /// Holds the validation logic for standard credit card inputs.
  const PaymentForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.cardController,
    required this.expiryController,
    required this.cvvController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Cardholder Name'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cardController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Card Number'),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (val.length != 16) return 'Must be 16 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryController,
                  decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(val)) return 'Format MM/YY';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length < 3 || val.length > 4) return 'Invalid CVV';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
