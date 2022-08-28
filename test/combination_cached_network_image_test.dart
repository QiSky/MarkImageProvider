import 'package:flutter_test/flutter_test.dart';
import 'package:combination_cached_network_image/combination_cached_network_image.dart';
import 'package:combination_cached_network_image/combination_cached_network_image_platform_interface.dart';
import 'package:combination_cached_network_image/combination_cached_network_image_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCombinationCachedNetworkImagePlatform 
    with MockPlatformInterfaceMixin
    implements CombinationCachedNetworkImagePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CombinationCachedNetworkImagePlatform initialPlatform = CombinationCachedNetworkImagePlatform.instance;

  test('$MethodChannelCombinationCachedNetworkImage is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCombinationCachedNetworkImage>());
  });

  test('getPlatformVersion', () async {
    CombinationCachedNetworkImage combinationCachedNetworkImagePlugin = CombinationCachedNetworkImage();
    MockCombinationCachedNetworkImagePlatform fakePlatform = MockCombinationCachedNetworkImagePlatform();
    CombinationCachedNetworkImagePlatform.instance = fakePlatform;
  
    expect(await combinationCachedNetworkImagePlugin.getPlatformVersion(), '42');
  });
}
