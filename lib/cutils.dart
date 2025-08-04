
import 'cutils_platform_interface.dart';

class Cutils {
  Future<String?> getPlatformVersion() {
    return CutilsPlatform.instance.getPlatformVersion();
  }
}
