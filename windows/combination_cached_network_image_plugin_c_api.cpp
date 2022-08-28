#include "include/combination_cached_network_image/combination_cached_network_image_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "combination_cached_network_image_plugin.h"

void CombinationCachedNetworkImagePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  combination_cached_network_image::CombinationCachedNetworkImagePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
