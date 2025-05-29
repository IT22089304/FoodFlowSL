import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploader {
  static Future<String?> uploadImage(
    File imageFile, {
    String folder = 'donations',
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final uploadTask = await ref.putFile(imageFile, metadata);
      final url = await uploadTask.ref.getDownloadURL();

      return url;
    } catch (e) {
      print("❌ Firebase upload error: $e");
      return null;
    }
  }
}
