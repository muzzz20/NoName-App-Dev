import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/campaign_service.dart';
import '../models/campaign_model.dart';
import '../models/campaign_failure.dart';
import '../widgets/allocation_entry_form.dart';

class CampaignFormScreen extends StatefulWidget {
  /// Unified screen for creating a new campaign or editing an existing one.
  const CampaignFormScreen({super.key});

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CampaignService();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _goalController = TextEditingController();
  
  List<AllocationEntry> _allocations = [];
  bool _isLoading = false;

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final model = CampaignModel(
      id: 'NEW', // STUB: Generate ID in real backend
      title: _titleController.text,
      description: _descController.text,
      goalAmount: double.tryParse(_goalController.text) ?? 0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      allocations: _allocations,
    );

    try {
      // BR-001: signInAnonymously() would be called here before Supabase upload.
      // Image upload stub goes here.
      await _service.saveCampaign(model);
      if (!mounted) return;
      context.pop(); // Returns to the management list
    } on CampaignFailure catch (e) {
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
        title: const Text('Campaign Form', style: TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Campaign Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Goal Amount (RM)'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if ((double.tryParse(val) ?? 0) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // DEPENDENCY NEEDED: image_picker — reason: For cover image selection
              Container(
                height: 150,
                color: AppColors.surfaceContainerHigh,
                child: const Center(child: Text('Cover Image Selection (Stub)')),
              ),
              const SizedBox(height: 24),
              AllocationEntryForm(
                initialAllocations: _allocations,
                onChanged: (allocs) => _allocations = allocs,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: AppColors.onPrimary)
                    : const Text('Save Campaign', style: TextStyle(color: AppColors.onPrimary, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
