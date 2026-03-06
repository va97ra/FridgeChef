import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final photoInputServiceProvider = Provider<PhotoInputService>((ref) {
  return const PhotoInputService();
});

class PhotoInputService {
  const PhotoInputService();

  Future<String?> pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      requestFullMetadata: false,
    );
    return image?.path;
  }

  Future<String?> pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      requestFullMetadata: false,
    );
    return image?.path;
  }
}
