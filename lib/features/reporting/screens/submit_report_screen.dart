import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import '../services/location_service.dart';
import '../services/photo_upload_service.dart';
import '../services/reports_service.dart';

/// Submit Report screen — UC-05 / NAD-11.
/// Matches `mockup-screens/report_cat_screen.png`.
class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationLabelController = TextEditingController();

  final _photoService = PhotoUploadService();
  final _locationService = LocationService();
  final _reportsService = ReportsService();

  String? _photoUrl;
  bool _photoUploading = false;
  String? _photoError;

  GeoPoint? _location;
  bool _locationLoading = false;
  String? _locationError;

  CatCondition? _condition;

  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _photoUrl != null &&
      _location != null &&
      _condition != null &&
      !_submitting &&
      !_photoUploading &&
      !_locationLoading;

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      _photoError = null;
      _photoUploading = true;
    });
    try {
      final url = await _photoService.pickAndUpload(source: source);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } on PhotoUploadFailure catch (e) {
      if (!mounted) return;
      setState(() => _photoError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoError = 'Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() {
      _locationError = null;
      _locationLoading = true;
    });
    try {
      final point = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _location = point);
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  /// Fallback for laptops without GPS / web origins where the geolocator
  /// API is denied. Drops a pin at UTM JB main campus center so the demo
  /// path always has a valid location.
  void _useCampusFallback() {
    setState(() {
      _location = const GeoPoint(1.5599, 103.6418); // UTM JB main campus
      _locationError = null;
      if (_locationLabelController.text.trim().isEmpty) {
        _locationLabelController.text = 'UTM Johor Bahru (campus center)';
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _submitError = 'You must be signed in to submit a report.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final report = await _reportsService.createReport(
        userId: user.uid,
        photoUrl: _photoUrl!,
        location: _location!,
        condition: _condition!,
        description: _descriptionController.text.trim(),
        locationLabel: _locationLabelController.text.trim().isEmpty
            ? null
            : _locationLabelController.text.trim(),
      );
      if (!mounted) return;
      context.go('${AppRoutes.reportSuccess}?id=${report.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = 'Could not submit report: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Stray Cat'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel('Cat Photo'),
                const SizedBox(height: AppSpacing.stackSm),
                _PhotoUploadCard(
                  photoUrl: _photoUrl,
                  uploading: _photoUploading,
                  errorMessage: _photoError,
                  onTap: _photoUploading ? null : _showPhotoSourceSheet,
                  onClear: _photoUploading || _photoUrl == null
                      ? null
                      : () => setState(() => _photoUrl = null),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                _SectionLabel('Location'),
                const SizedBox(height: AppSpacing.stackSm),
                _LocationField(
                  geoPoint: _location,
                  loading: _locationLoading,
                  errorMessage: _locationError,
                  labelController: _locationLabelController,
                  onDetect: _locationLoading ? null : _detectLocation,
                  onCampusFallback:
                      _locationLoading ? null : _useCampusFallback,
                  onClear: _location == null
                      ? null
                      : () => setState(() => _location = null),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                _SectionLabel('Condition'),
                const SizedBox(height: AppSpacing.stackSm),
                _ConditionDropdown(
                  value: _condition,
                  onChanged: (v) => setState(() => _condition = v),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                _SectionLabel('Description (optional)'),
                const SizedBox(height: AppSpacing.stackSm),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe the cat\'s situation, e.g. limping near KTR',
                  ),
                ),

                if (_submitError != null) ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  _ErrorBanner(message: _submitError!),
                ],

                const SizedBox(height: AppSpacing.stackXl),

                ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Submit Report'),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.labelCaps);
  }
}

class _PhotoUploadCard extends StatelessWidget {
  final String? photoUrl;
  final bool uploading;
  final String? errorMessage;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _PhotoUploadCard({
    required this.photoUrl,
    required this.uploading,
    required this.errorMessage,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Container(
            height: 192,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.cardRadius,
              border: hasPhoto
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: AppRadius.cardRadius,
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.outline, size: 36),
                      ),
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: uploading
                            ? AppColors.outline
                            : AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        uploading
                            ? 'Uploading…'
                            : 'Tap to add a photo',
                        style: AppText.bodySm
                            .copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                if (uploading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: AppRadius.cardRadius,
                    ),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.onPrimary,
                    ),
                  ),
                if (hasPhoto && !uploading && onClear != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      shape: const CircleBorder(),
                      color: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.onPrimary, size: 18),
                        onPressed: onClear,
                        tooltip: 'Remove photo',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            errorMessage!,
            style: AppText.bodySm.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  final GeoPoint? geoPoint;
  final bool loading;
  final String? errorMessage;
  final TextEditingController labelController;
  final VoidCallback? onDetect;
  final VoidCallback? onCampusFallback;
  final VoidCallback? onClear;

  const _LocationField({
    required this.geoPoint,
    required this.loading,
    required this.errorMessage,
    required this.labelController,
    required this.onDetect,
    required this.onCampusFallback,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: labelController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_outlined),
                  hintText: 'e.g. Kolej Tun Razak, Block L50',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDetect,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  geoPoint == null
                      ? 'Use my location'
                      : '${geoPoint!.latitude.toStringAsFixed(5)}, '
                          '${geoPoint!.longitude.toStringAsFixed(5)}',
                ),
              ),
            ),
            if (geoPoint != null && onClear != null) ...[
              const SizedBox(width: AppSpacing.stackSm),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear, color: AppColors.outline),
                tooltip: 'Clear coordinates',
              ),
            ],
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.stackXs),
          Text(
            errorMessage!,
            style: AppText.bodySm.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextButton.icon(
            onPressed: onCampusFallback,
            icon: const Icon(Icons.school_outlined, size: 16),
            label: const Text('Use UTM campus instead'),
          ),
        ],
      ],
    );
  }
}

class _ConditionDropdown extends StatelessWidget {
  final CatCondition? value;
  final ValueChanged<CatCondition?> onChanged;
  const _ConditionDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CatCondition>(
      initialValue: value,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.health_and_safety_outlined),
        hintText: 'Select condition',
      ),
      items: CatCondition.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Pick a condition.' : null,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackMd,
        vertical: AppSpacing.stackSm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.onErrorContainer),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(
              message,
              style: AppText.bodySm.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
