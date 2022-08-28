
import 'combination_cached_network_image_platform_interface.dart';

class CombinationCachedNetworkImage {
  Future<String?> getPlatformVersion() {
    return CombinationCachedNetworkImagePlatform.instance.getPlatformVersion();
  }
}
