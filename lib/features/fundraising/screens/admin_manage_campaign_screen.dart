import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../reporting/services/photo_upload_service.dart';
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

  // Cover image is uploaded (like Submit Report), not pasted as a URL.
  final _photoService = PhotoUploadService();
  String? _imageUrl;
  bool _photoUploading = false;
  String? _photoError;

  final List<Map<String, TextEditingController>> _allocations = [];
  bool _isSaving = false;

  final _campaignsService = CampaignsService();
  final _allocationsService = AllocationsService();

  Future<void> _pickCover(ImageSource source) async {
    setState(() {
      _photoUploading = true;
      _photoError = null;
    });
    try {
      final url = await _photoService.pickAndUpload(
          source: source, folder: 'campaign-photos');
      if (mounted) setState(() => _imageUrl = url);
    } on PhotoUploadFailure catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } catch (e) {
      if (mounted) setState(() => _photoError = 'Could not upload image: $e');
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  void _showCoverSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCover(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCover(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Cap on transparency line items — keeps the donor-facing breakdown
  /// readable and the form sane.
  static const int _maxAllocations = 8;

  void _addAllocation() {
    if (_allocations.length >= _maxAllocations) return;
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
    for (var controllers in _allocations) {
      controllers['label']!.dispose();
      controllers['amount']!.dispose();
    }
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a cover photo.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one allocation item (where the money goes).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final goalAmount = double.parse(_goalController.text);
    
    // Calculate total allocation sum
    double totalAllocated = 0;
    for (final allocCtrl in _allocations) {
      final amountText = allocCtrl['amount']!.text;
      totalAllocated += double.tryParse(amountText) ?? 0;
    }

    if ((totalAllocated - goalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The sum of allocations (RM ${totalAllocated.toStringAsFixed(2)}) must exactly match the Goal Amount (RM ${goalAmount.toStringAsFixed(2)}).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw const CampaignFailure('You must be signed in.');
      final createdBy = user.uid;

      final days = int.parse(_daysController.text);
      
      final campaign = await _campaignsService.createCampaign(
        createdBy: createdBy,
        title: _titleController.text,
        description: _descriptionController.text,
        goalAmountSen: (goalAmount * 100).toInt(),
        imageUrl: _imageUrl!,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign created successfully!')),
      );
      context.canPop() ? context.pop() : context.go('/campaigns');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is CampaignFailure
              ? e.message
              : "Couldn't save the campaign. Please try again."),
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/campaigns'),
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
                    // Cover image — uploaded like a report photo.
                    Text('Cover Photo', style: AppText.titleSm),
                    const SizedBox(height: AppSpacing.stackSm),
                    GestureDetector(
                      onTap: _photoUploading ? null : _showCoverSourceSheet,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: _photoUploading
                              ? const Center(child: CircularProgressIndicator())
                              : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 40,
                                                color: AppColors.outline),
                                          ),
                                        ),
                                        Positioned(
                                          right: AppSpacing.stackSm,
                                          bottom: AppSpacing.stackSm,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.stackSm,
                                                vertical: 4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: AppRadius.pillRadius,
                                            ),
                                            child: Text('Change photo',
                                                style: AppText.labelCaps
                                                    .copyWith(
                                                        color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_a_photo_outlined,
                                            size: 40, color: AppColors.primary),
                                        const SizedBox(
                                            height: AppSpacing.stackSm),
                                        Text('Tap to add a cover photo',
                                            style: AppText.bodySm.copyWith(
                                                color: AppColors.outline)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    if (_photoError != null) ...[
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(_photoError!,
                          style: AppText.bodySm
                              .copyWith(color: AppColors.error)),
                    ],

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
                        Expanded(
                          child: Text('Allocations (Where money goes)',
                              style: AppText.titleSm),
                        ),
                        if (_allocations.length < _maxAllocations)
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: AppColors.primary),
                            onPressed: _addAllocation,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.stackSm),
                            child: Text('Max $_maxAllocations',
                                style: AppText.bodySm
                                    .copyWith(color: AppColors.outline)),
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
