import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Helper class untuk handle image display dari base64 atau URL
class ImageHelper {
  /// Validasi dan bersihkan base64 string
  static String _cleanBase64String(String base64String) {
    // Remove whitespace
    String cleaned = base64String.replaceAll(RegExp(r'\s'), '');

    // Add padding jika diperlukan
    final paddingNeeded = cleaned.length % 4;
    if (paddingNeeded != 0) {
      cleaned += '=' * (4 - paddingNeeded);
    }

    return cleaned;
  }

  /// Validasi base64 string format dengan error detail
  static bool _isValidBase64(String base64String) {
    try {
      if (base64String.isEmpty) return false;

      final cleaned = _cleanBase64String(base64String);

      // Base64 hanya boleh berisi A-Z, a-z, 0-9, +, /, =
      // Tapi untuk relaxed validation, coba langsung decode dulu
      try {
        base64Decode(cleaned);
        return true;
      } catch (e) {
        // Jika langsung decode fail, check karakter
        debugPrint('⚠️ [ImageHelper] Direct decode failed: $e');

        // Check untuk karakter invalid
        final validChars = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
        if (!validChars.hasMatch(cleaned)) {
          debugPrint(
            '❌ [ImageHelper] Invalid base64 characters detected in: ${cleaned.substring(0, 50)}...',
          );
          return false;
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ [ImageHelper] Base64 validation error: $e');
      return false;
    }
  }

  /// Build image widget dari base64 atau URL
  static Widget buildImage(
    String? imageData, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (imageData == null || imageData.isEmpty) {
      debugPrint('[ImageHelper] Empty image data, showing placeholder');
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
        child: const Icon(Icons.image_not_supported, size: 50),
      );
    }

    try {
      if (imageData.startsWith('data:image')) {
        // Data URL format: data:image/jpeg;base64,xxx
        debugPrint('[ImageHelper] Detected data URL format');
        final parts = imageData.split(',');
        if (parts.length < 2) {
          debugPrint(
            '❌ [ImageHelper] Invalid data URL format - missing comma separator',
          );
          return _buildPlaceholder(width, height, borderRadius);
        }

        final base64String = parts[1];
        return _buildBase64Image(
          base64String,
          width,
          height,
          fit,
          borderRadius,
        );
      } else if (imageData.startsWith('http')) {
        // URL image
        debugPrint('[ImageHelper] Loading image from URL: $imageData');
        Widget image = Image.network(
          imageData,
          fit: fit,
          errorBuilder: (_, __, ___) {
            debugPrint('[ImageHelper] Error loading network image');
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            );
          },
        );

        if (borderRadius != null) {
          image = ClipRRect(borderRadius: borderRadius, child: image);
        }

        return SizedBox(width: width, height: height, child: image);
      } else if (imageData.startsWith('assets/images/data:')) {
        // ❌ Error: Invalid data format dengan asset prefix
        debugPrint(
          '❌ [ImageHelper] Invalid image format - contains asset prefix in base64 data',
        );
        return _buildPlaceholder(width, height, borderRadius);
      } else {
        // Try to treat as pure base64 string
        debugPrint(
          '[ImageHelper] Attempting to decode as pure base64 string (length: ${imageData.length})',
        );
        return _buildBase64Image(imageData, width, height, fit, borderRadius);
      }
    } catch (e) {
      debugPrint('❌ [ImageHelper] Error: $e');
      return _buildPlaceholder(width, height, borderRadius);
    }
  }

  /// Build placeholder widget
  static Widget _buildPlaceholder(
    double? width,
    double? height,
    BorderRadius? borderRadius,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.image_not_supported, size: 50),
    );
  }

  /// Helper method to build image from base64 string
  static Widget _buildBase64Image(
    String base64String,
    double? width,
    double? height,
    BoxFit fit,
    BorderRadius? borderRadius,
  ) {
    try {
      debugPrint(
        '[ImageHelper] Decoding base64 image (length: ${base64String.length})',
      );

      // Handle empty atau very short strings
      if (base64String.length < 20) {
        debugPrint(
          '❌ [ImageHelper] Base64 string too short: ${base64String.length} chars',
        );
        return _buildPlaceholder(width, height, borderRadius);
      }

      // Clean base64 string
      final cleaned = _cleanBase64String(base64String);

      // Try to decode dengan error handling
      Uint8List bytes;
      try {
        bytes = base64Decode(cleaned);
      } catch (decodeError) {
        debugPrint('❌ [ImageHelper] Base64 decode failed: $decodeError');
        // Try alternative: remove padding dan decode
        try {
          final noPadding = cleaned.replaceAll('=', '');
          bytes = base64Decode(noPadding + '=' * (4 - noPadding.length % 4));
          debugPrint(
            '✓ [ImageHelper] Successfully decoded with padding adjustment',
          );
        } catch (e) {
          debugPrint('❌ [ImageHelper] Even padding adjustment failed: $e');
          return _buildPlaceholder(width, height, borderRadius);
        }
      }

      if (bytes.isEmpty) {
        debugPrint('❌ [ImageHelper] Decoded bytes is empty');
        return _buildPlaceholder(width, height, borderRadius);
      }

      debugPrint(
        '✓ [ImageHelper] Successfully decoded base64 to ${bytes.length} bytes',
      );

      Widget image = Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, __, ___) {
          debugPrint(
            '❌ [ImageHelper] Error displaying base64 image in Image.memory',
          );
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        },
      );

      if (borderRadius != null) {
        image = ClipRRect(borderRadius: borderRadius, child: image);
      }

      return SizedBox(width: width, height: height, child: image);
    } catch (e) {
      debugPrint('❌ [ImageHelper] Base64 decode error: $e');
      return _buildPlaceholder(width, height, borderRadius);
    }
  }

  /// Decode base64 image to Uint8List
  static Uint8List? decodeBase64(String imageData) {
    try {
      if (imageData.startsWith('data:image')) {
        final parts = imageData.split(',');
        if (parts.length < 2) {
          debugPrint('❌ [ImageHelper] Invalid data URL format');
          return null;
        }
        final base64String = parts[1];

        if (!_isValidBase64(base64String)) {
          debugPrint('❌ [ImageHelper] Invalid base64 string in data URL');
          return null;
        }

        final cleaned = _cleanBase64String(base64String);
        return base64Decode(cleaned);
      } else if (imageData.isNotEmpty) {
        // Try pure base64 string
        if (!_isValidBase64(imageData)) {
          debugPrint('❌ [ImageHelper] Invalid base64 string');
          return null;
        }

        final cleaned = _cleanBase64String(imageData);
        return base64Decode(cleaned);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ImageHelper] Decode error: $e');
      return null;
    }
  }
}
