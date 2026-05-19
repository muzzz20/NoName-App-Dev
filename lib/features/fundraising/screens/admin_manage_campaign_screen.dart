import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../services/campaigns_service.dart';
import '../services/allocations_service.dart';

class AdminManageCampaignScreen extends StatefulWidget {
  const AdminManageCampaignScreen({super.key});

  @override
  State<AdminManageCampaignScreen> createState() => _AdminManageCampaignScreenState();
}

class _AdminManageCampaignScreenState extends State<AdminManageCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  final _daysController = TextEditingController();
  final _imageUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=800',
  );

  final List<Map<String, TextEditingController>> _allocations = [];
  bool _isSaving = false;

  final _campaignsService = CampaignsService();
  final _allocationsService = AllocationsService();

  void _addAllocation() {
    setState(() {
      _allocations.add({
        'label': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      _allocations[index]['label']!.dispose();
      _allocations[index]['amount']!.dispose();
      _allocations.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _daysController.dispose();
    _imageUrlController.dispose();
    for (var controllers in _allocations) {
      controllers['label']!.dispose();
      controllers['amount']!.dispose();
    }
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final createdBy = user?.uid ?? 'admin_user_123';
      
      final goalAmount = double.parse(_goalController.text);
      final days = int.parse(_daysController.text);
      
      final campaign = await _campaignsService.createCampaign(
        createdBy: createdBy,
        title: _titleController.text,
        description: _descriptionController.text,
        goalAmountSen: (goalAmount * 100).toInt(),
        imageUrl: _imageUrlController.text.trim(),
        endsAt: DateTime.now().add(Duration(days: days)),
      );
      
      // Save all allocations
      for (final allocCtrl in _allocations) {
        final purpose = allocCtrl['label']!.text;
        final amount = double.parse(allocCtrl['amount']!.text);
        
        await _allocationsService.createAllocation(
          campaignId: campaign.id,
          amountSen: (amount * 100).toInt(),
          purpose: purpose,
          createdBy: createdBy,
        );
      }
      
      if (!mounted) return;
      setState(() => _isSaving = false);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving campaign: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Campaign'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image URL and Live Preview
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Image URL',
                        prefixIcon: Icon(Icons.image),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.network(
                          _imageUrlController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 40, color: AppColors.outline),
                              const SizedBox(height: AppSpacing.stackSm),
                              Text('No image preview available', style: AppText.bodySm.copyWith(color: AppColors.outline)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Basic Details', style: AppText.titleSm),
                    const SizedBox(height: AppSpacing.stackMd),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Campaign Title'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _goalController,
                            decoration: const InputDecoration(
                              labelText: 'Goal Amount (RM)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: TextFormField(
                            controller: _daysController,
                            decoration: const InputDecoration(
                              labelText: 'Days to run',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.stackLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Allocations (Where money goes)', style: AppText.titleSm),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: _addAllocation,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    ..._allocations.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final controllers = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: controllers['label'],
                                decoration: const InputDecoration(hintText: 'e.g. Vet Bills'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackSm),
                            Expanded(
                              child: TextFormField(
                                controller: controllers['amount'],
                                decoration: const InputDecoration(hintText: 'RM'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _removeAllocation(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_allocations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.stackLg),
                        child: Center(
                          child: Text(
                            'Add transparency items to build trust with donors.',
                            style: AppText.bodySm.copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
