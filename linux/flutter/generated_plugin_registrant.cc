//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <bitsdojo_window_linux/bitsdojo_window_plugin.h>
#include <libwinmedia/libwinmedia_plugin.h>
#include <multi_window_linux/multi_window_linux_plugin.h>
#include <sentry_flutter/sentry_flutter_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) bitsdojo_window_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "BitsdojoWindowPlugin");
  bitsdojo_window_plugin_register_with_registrar(bitsdojo_window_linux_registrar);
  g_autoptr(FlPluginRegistrar) libwinmedia_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LibwinmediaPlugin");
  libwinmedia_plugin_register_with_registrar(libwinmedia_registrar);
  g_autoptr(FlPluginRegistrar) multi_window_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MultiWindowLinuxPlugin");
  multi_window_linux_plugin_register_with_registrar(multi_window_linux_registrar);
  g_autoptr(FlPluginRegistrar) sentry_flutter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SentryFlutterPlugin");
  sentry_flutter_plugin_register_with_registrar(sentry_flutter_registrar);
}
