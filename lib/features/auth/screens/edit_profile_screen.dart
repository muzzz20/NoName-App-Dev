import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../reporting/services/photo_upload_service.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Edit Profile (UC-04) — display name + avatar + reset password.
///
/// Email is shown read-only. Role is NEVER touched: [AuthService.updateProfile]
/// sends only name/photoUrl, satisfying the users update rule (self + role
/// unchanged). The avatar uploads to the owner-scoped `avatars/{uid}` path.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  final _photoService = PhotoUploadService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  UserProfile? _profile;
  String? _photoUrl;
  bool _loading = true;
  bool _uploadingPhoto = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _auth.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _nameController.text = p?.fullName ?? '';
      _photoUrl = p?.photoUrl;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    try {
      final url = await _photoService.pickAndUpload(
          source: source, folder: 'avatars/$uid');
      if (mounted) setState(() => _photoUrl = url);
    } on PhotoUploadFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not upload photo: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoSheet() {
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
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _auth.updateProfile(
        fullName: _nameController.text.trim(),
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save changes: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _profile?.email ?? FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await _auth.sendPasswordReset(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send the reset email.')));
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
        title: const Text('Edit Profile'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              backgroundImage: _photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                              child: _photoUrl == null
                                  ? Text(
                                      _initials(_nameController.text),
                                      style: AppText.headlineMd
                                          .copyWith(color: AppColors.primary),
                                    )
                                  : null,
                            ),
                            if (_uploadingPhoto)
                              const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Center(
                        child: TextButton.icon(
                          onPressed: _uploadingPhoto ? null : _showPhotoSheet,
                          icon: const Icon(Icons.photo_camera_outlined,
                              size: 18),
                          label: const Text('Change photo'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Display name'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      Text('Email', style: AppText.labelCaps),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.email ?? '',
                        style: AppText.bodyBase
                            .copyWith(color: AppColors.secondary),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      if (_error != null) ...[
                        Text(_error!,
                            style: AppText.bodySm
                                .copyWith(color: AppColors.error)),
                        const SizedBox(height: AppSpacing.stackMd),
                      ],
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onPrimary),
                              )
                            : const Text('Save Changes'),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      OutlinedButton.icon(
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.lock_reset_outlined),
                        label: const Text('Reset password'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
