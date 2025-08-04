import 'package:flutter_test/flutter_test.dart';
import 'package:cutils/cutils.dart';
import 'package:cutils/cutils_platform_interface.dart';
import 'package:cutils/cutils_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCutilsPlatform
    with MockPlatformInterfaceMixin
    implements CutilsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CutilsPlatform initialPlatform = CutilsPlatform.instance;

  test('$MethodChannelCutils is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCutils>());
  });

  test('getPlatformVersion', () async {
    Cutils cutilsPlugin = Cutils();
    MockCutilsPlatform fakePlatform = MockCutilsPlatform();
    CutilsPlatform.instance = fakePlatform;

    expect(await cutilsPlugin.getPlatformVersion(), '42');
  });
}
