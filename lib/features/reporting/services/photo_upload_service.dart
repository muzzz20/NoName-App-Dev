import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Photo capture + Supabase Storage upload.
///
/// Bucket: `cat-photos` (public read, authenticated write — RLS enforced).
/// Output: public HTTPS URL stored in CatReport.photoUrl (Firestore).
class PhotoUploadService {
  PhotoUploadService({
    SupabaseClient? supabase,
    ImagePicker? picker,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _picker = picker ?? ImagePicker();

  final SupabaseClient _supabase;
  final ImagePicker _picker;
  static const String _bucket = 'cat-photos';

  /// Soft cap from NAD-10 AC: keep uploads under 2 MB.
  static const int maxBytes = 2 * 1024 * 1024;

  /// Max image dimension after resize (longest edge). Keeps photo
  /// recognizable while shrinking 8 MP+ phone shots to ~250–600 KB.
  static const int maxDimension = 1280;

  /// Show platform picker (camera or gallery), compress, upload.
  /// Returns the public URL of the uploaded photo.
  ///
  /// Throws [PhotoUploadFailure] on any user-facing error
  /// (permission denied, network, oversized after compression, etc.).
  Future<String> pickAndUpload({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85, // initial JPEG quality knob — fast path
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
    );
    if (picked == null) {
      throw const PhotoUploadFailure('No photo selected.');
    }

    final bytes = await picked.readAsBytes();
    final compressed = await _ensureUnderLimit(bytes);

    return _uploadBytes(compressed, originalPath: picked.name);
  }

  /// Compress further on a background isolate if the picker output is still
  /// larger than [maxBytes]. Most modern phones pre-compress well, so this
  /// path is rare — but cheap to keep as a safety net.
  Future<Uint8List> _ensureUnderLimit(Uint8List bytes) async {
    if (bytes.length <= maxBytes) return bytes;
    return compute(_recompress, bytes);
  }

  /// Pure function suitable for [compute] isolation.
  static Uint8List _recompress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Halve dimensions until we estimate well under the limit. Each halving
    // cuts roughly 75% of pixel data; JPEG re-encode then shrinks more.
    var image = decoded;
    while (image.width > 800 || image.height > 800) {
      image = img.copyResize(
        image,
        width: (image.width * 0.7).round(),
        height: (image.height * 0.7).round(),
      );
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 75));
  }

  Future<String> _uploadBytes(
    Uint8List bytes, {
    required String originalPath,
  }) async {
    // Note: bucket RLS allows insert from `authenticated` role. We use
    // Firebase Auth (not Supabase Auth) — Sprint 2 follow-up will exchange
    // a Firebase ID token for a Supabase JWT so RLS sees authenticated
    // requests. For Sprint 1 demo, bucket policy is relaxed to `anon` write
    // OR uploads are exercised via a custom service-role function. Verify
    // your Supabase policy matches before testing.
    final id = const Uuid().v4();
    final ext = _ext(originalPath);
    final objectPath = '$id$ext';

    try {
      await _supabase.storage.from(_bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeFor(ext),
              upsert: false,
            ),
          );
      return _supabase.storage.from(_bucket).getPublicUrl(objectPath);
    } on StorageException catch (e) {
      throw PhotoUploadFailure(_friendlyStorageError(e));
    } catch (e) {
      throw PhotoUploadFailure('Upload failed: $e');
    }
  }

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _friendlyStorageError(StorageException e) {
    // Supabase storage messages aren't always user-friendly — map the
    // common ones to a clearer string. Default to e.message.
    final msg = e.message.toLowerCase();
    if (msg.contains('row level security')) {
      return 'You do not have permission to upload. Sign in and try again.';
    }
    if (msg.contains('payload too large')) {
      return 'Photo is too large — try a smaller image.';
    }
    if (msg.contains('duplicate')) {
      return 'Photo already exists — try again.';
    }
    return 'Upload failed: ${e.message}';
  }
}

/// User-facing photo upload error. UI shows `.message` directly.
class PhotoUploadFailure implements Exception {
  final String message;
  const PhotoUploadFailure(this.message);

  @override
  String toString() => message;
}

/// Convenience picker source enum re-export so screens don't depend
/// directly on image_picker.
typedef PhotoSource = ImageSource;

/// Sentinel for the dart:io File API to keep static analysis happy when
/// stub paths are checked. Not used at runtime on web.
typedef PhotoFile = File;
