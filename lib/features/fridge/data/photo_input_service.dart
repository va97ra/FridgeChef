import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

final photoInputServiceProvider = Provider<PhotoInputService>((ref) {
  return const PhotoInputService();
});

enum PhotoPermissionState { granted, denied, permanentlyDenied, unavailable }

class PhotoInputPickResult {
  final String? imagePath;
  final PhotoPermissionState permissionState;
  final bool cancelled;

  const PhotoInputPickResult({
    required this.permissionState,
    this.imagePath,
    this.cancelled = false,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
}

class PhotoInputService {
  const PhotoInputService();

  Future<PhotoInputPickResult> pickFromCamera() async {
    final permissionState = await _ensureCameraPermission();
    if (permissionState != PhotoPermissionState.granted) {
      return PhotoInputPickResult(permissionState: permissionState);
    }

    return _pickImage(ImageSource.camera);
  }

  Future<PhotoInputPickResult> pickFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<PhotoPermissionState> _ensureCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        return PhotoPermissionState.granted;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        return PhotoPermissionState.permanentlyDenied;
      }

      final requested = await Permission.camera.request();
      if (requested.isGranted) {
        return PhotoPermissionState.granted;
      }
      if (requested.isPermanentlyDenied || requested.isRestricted) {
        return PhotoPermissionState.permanentlyDenied;
      }
      return PhotoPermissionState.denied;
    } catch (_) {
      return PhotoPermissionState.unavailable;
    }
  }

  Future<PhotoInputPickResult> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (image == null || image.path.isEmpty) {
        return const PhotoInputPickResult(
          permissionState: PhotoPermissionState.granted,
          cancelled: true,
        );
      }

      return PhotoInputPickResult(
        permissionState: PhotoPermissionState.granted,
        imagePath: image.path,
      );
    } on PlatformException {
      return const PhotoInputPickResult(
        permissionState: PhotoPermissionState.unavailable,
      );
    } catch (_) {
      return const PhotoInputPickResult(
        permissionState: PhotoPermissionState.unavailable,
      );
    }
  }
}
