import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'combination_cached_network_image_method_channel.dart';

abstract class CombinationCachedNetworkImagePlatform extends PlatformInterface {
  /// Constructs a CombinationCachedNetworkImagePlatform.
  CombinationCachedNetworkImagePlatform() : super(token: _token);

  static final Object _token = Object();

  static CombinationCachedNetworkImagePlatform _instance = MethodChannelCombinationCachedNetworkImage();

  /// The default instance of [CombinationCachedNetworkImagePlatform] to use.
  ///
  /// Defaults to [MethodChannelCombinationCachedNetworkImage].
  static CombinationCachedNetworkImagePlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CombinationCachedNetworkImagePlatform] when
  /// they register themselves.
  static set instance(CombinationCachedNetworkImagePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
