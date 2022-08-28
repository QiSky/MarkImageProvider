import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:combination_cached_network_image/combination_cached_network_image_method_channel.dart';

void main() {
  MethodChannelCombinationCachedNetworkImage platform = MethodChannelCombinationCachedNetworkImage();
  const MethodChannel channel = MethodChannel('combination_cached_network_image');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
