import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Dart wrapper for the `com.kids_bank_app/image_picker` Method Channel.
/// Launches the native iOS PHPickerViewController and returns the selected
/// image as JPEG bytes, or null if the user cancels.
class ImagePickerChannel {
  static const _channel = MethodChannel('com.kids_bank_app/image_picker');

  /// Opens the native photo library picker.
  /// Returns the selected image as JPEG [Uint8List], or null if cancelled.
  static Future<Uint8List?> pickImageFromGallery() async {
    final result = await _channel.invokeMethod<Uint8List>('pickImage');
    return result;
  }
}
