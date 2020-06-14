shared_library(
  'opensearchplugin',
  files(
    'src/Main.vala'
  ),
  vala_args: common_vala_flags,
  link_with: [libsynapse_lib],
  dependencies: [
    gee_dep,
    gio_dep,
    glib_dep,
    gtk_dep
  ],
  include_directories: [libsynapse_include_dir],
  install: true,
  install_dir: plugins_dir
)

subdir('po')
