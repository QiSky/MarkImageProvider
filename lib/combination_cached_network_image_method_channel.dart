import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'combination_cached_network_image_platform_interface.dart';

/// An implementation of [CombinationCachedNetworkImagePlatform] that uses method channels.
class MethodChannelCombinationCachedNetworkImage extends CombinationCachedNetworkImagePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('combination_cached_network_image');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
