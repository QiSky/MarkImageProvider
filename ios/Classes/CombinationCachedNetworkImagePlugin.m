#import "CombinationCachedNetworkImagePlugin.h"
#if __has_include(<combination_cached_network_image/combination_cached_network_image-Swift.h>)
#import <combination_cached_network_image/combination_cached_network_image-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "combination_cached_network_image-Swift.h"
#endif

@implementation CombinationCachedNetworkImagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCombinationCachedNetworkImagePlugin registerWithRegistrar:registrar];
}
@end
