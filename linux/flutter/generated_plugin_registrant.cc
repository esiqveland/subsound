//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <libwinmedia/libwinmedia_plugin.h>
#include <sentry_flutter/sentry_flutter_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) libwinmedia_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LibwinmediaPlugin");
  libwinmedia_plugin_register_with_registrar(libwinmedia_registrar);
  g_autoptr(FlPluginRegistrar) sentry_flutter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SentryFlutterPlugin");
  sentry_flutter_plugin_register_with_registrar(sentry_flutter_registrar);
}
