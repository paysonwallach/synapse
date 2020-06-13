synapse_ui_sources = [
  'Category.vala',
  'Controller.vala',
  'DataSink.vala',
  'IconCacheService.vala',
  'Interfaces.vala',
  'Keybindings.vala',
  'Main.vala',
  'MatchListViewWidgets.vala',
  'Model.vala',
  'PluginRegistry.vala',
  'SearchEntry.vala',
  'Settings.vala',
  'Widgets.vala',
  'Utils.vala'
]

subdir('TileView')
subdir('Themes')

synapse_ui_dependencies = [
  gdk_dep,
  gee_dep,
  gio_dep,
  glib_dep,
  gmodule_dep,
  gtk_dep,
  keybinder_dep,
  notify_dep,
  m_dep,
  synapse_dep,
  config_dep
]

executable(
  meson.project_name(),
  synapse_ui_sources,
  synapse_themes_sources,
  include_directories: config_inc_dir,
  dependencies: synapse_ui_dependencies,
  install: true,
)
