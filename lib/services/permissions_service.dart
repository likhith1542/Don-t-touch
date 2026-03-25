import 'package:permission_handler/permission_handler.dart';
import 'package:local_auth/local_auth.dart';

class PermissionsService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();

    return {
      'camera': results[Permission.camera]?.isGranted ?? false,
      'microphone': results[Permission.microphone]?.isGranted ?? false,
      'notification': results[Permission.notification]?.isGranted ?? false,
      'battery': results[Permission.ignoreBatteryOptimizations]?.isGranted ?? false,
    };
  }

  static Future<bool> hasBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to disable alarm',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
