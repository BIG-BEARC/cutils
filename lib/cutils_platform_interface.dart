import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cutils_method_channel.dart';

abstract class CutilsPlatform extends PlatformInterface {
  /// Constructs a CutilsPlatform.
  CutilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static CutilsPlatform _instance = MethodChannelCutils();

  /// The default instance of [CutilsPlatform] to use.
  ///
  /// Defaults to [MethodChannelCutils].
  static CutilsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CutilsPlatform] when
  /// they register themselves.
  static set instance(CutilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
