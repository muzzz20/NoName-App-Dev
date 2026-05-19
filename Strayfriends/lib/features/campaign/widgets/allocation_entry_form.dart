import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../../../core/theme/app_colors.dart';

class AllocationEntryForm extends StatefulWidget {
  final List<AllocationEntry> initialAllocations;
  final ValueChanged<List<AllocationEntry>> onChanged;

  /// Sub-form for appending multiple fund allocation categories.
  const AllocationEntryForm({
    super.key,
    required this.initialAllocations,
    required this.onChanged,
  });

  @override
  State<AllocationEntryForm> createState() => _AllocationEntryFormState();
}

class _AllocationEntryFormState extends State<AllocationEntryForm> {
  late List<AllocationEntry> _allocations;
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allocations = List.from(widget.initialAllocations);
  }

  void _addEntry() {
    final label = _labelController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (label.isNotEmpty && amount > 0) {
      setState(() {
        _allocations.add(AllocationEntry(label: label, amount: amount));
        widget.onChanged(_allocations);
      });
      _labelController.clear();
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Fund Allocations', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._allocations.map((a) => ListTile(
          title: Text(a.label),
          trailing: Text('RM ${a.amount.toStringAsFixed(2)}'),
          contentPadding: EdgeInsets.zero,
        )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'RM'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: _addEntry,
            ),
          ],
        )
      ],
    );
  }
}
