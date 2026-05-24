import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      final biometrics = await auth.getAvailableBiometrics();

      print("SUPPORTED: $supported");
      print("CAN CHECK: $canCheck");
      print("BIOMETRICS: $biometrics");

      if (!supported || !canCheck || biometrics.isEmpty) {
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk SmartPay AI',
        biometricOnly: true,
      );
    } catch (e) {
      print("BIOMETRIC ERROR: $e");
      return false;
    }
  }
}