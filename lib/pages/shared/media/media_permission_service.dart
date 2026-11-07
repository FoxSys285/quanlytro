import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum RentalMediaKind { image, video }

/// The app uses the platform picker so it receives only the media the user
/// selects. We inspect library permission at entry and before each picker;
/// the picker itself grants scoped access on Android/iOS when broad access is
/// unavailable.
class MediaPermissionService {
  MediaPermissionService._();

  static Future<void> checkAtAppEntry() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    await Future.wait([Permission.photos.status, Permission.videos.status]);
  }

  static Future<bool> checkBeforePicker(RentalMediaKind kind) async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return true;
    }
    final permission = kind == RentalMediaKind.image
        ? Permission.photos
        : Permission.videos;
    final status = await permission.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      // Android's system photo picker can still grant access to individual
      // selected files without granting broad media-library access.
      if (defaultTargetPlatform == TargetPlatform.android) return true;
      await openAppSettings();
      return false;
    }
    if (status.isDenied) {
      final requested = await permission.request();
      if (requested.isPermanentlyDenied || requested.isRestricted) {
        if (defaultTargetPlatform == TargetPlatform.android) return true;
        await openAppSettings();
        return false;
      }
    }
    return true;
  }

  static Future<XFile?> pickVideo({Duration? maxDuration}) async {
    if (!await checkBeforePicker(RentalMediaKind.video)) return null;
    return ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
  }
}
