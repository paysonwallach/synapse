libsynapse_sources = files(
  'CommonActions.vala',
  'ConfigService.vala',
  'DBusService.vala',
  'DesktopFileService.vala',
  'Match.vala',
  'Plugin.vala',
  'Query.vala',
  'RelevancyService.vala',
  'ResultSet.vala',
  'SearchProvider.vala',
  'Utils.vala',
  'VolumeService.vala'
)

libsynapse_dependencies = [
  gee_dep,
  gio_dep,
  gio_unix_dep,
  glib_dep,
  glib_json_dep,
  gtk_dep,
]
libsynapse_requires = libsynapse_dependencies

libsynapse_vala_flags = []

if conf.has('HAVE_ZEITGEIST')
  libsynapse_sources += files('RelevancyBackendZeitgeist.vala')
  libsynapse_dependencies += [
    m_dep,
    zeitgeist_dep
  ]
  libsynapse_vala_flags += zeitgeist_vala_flags
endif

add_project_arguments(libsynapse_vala_flags, language: 'vala')

libsynapse_lib = shared_library(
  'synapse-1.0',
  libsynapse_sources,
  dependencies: libsynapse_dependencies,
  vala_header: 'synapse.h',
  soversion: '0',
  install: true,
  install_dir: [
    true,
    join_paths(get_option('includedir'), 'synapse'),
    true
  ],
)

pkg.generate(
  filebase: 'synapse-1.0',
  name: 'Synapse',
  description: 'Core library for Synapse and plugins',
  version: meson.project_version(),
  subdirs: 'synapse-1.0',
  variables: ['pluginsdir=${plugins_dir}'],
  libraries: libsynapse_lib,
  requires: libsynapse_requires
)

install_data(
  'synapse-1.0.deps',
  install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

libsynapse_include_dir = include_directories('.')
synapse_dep = declare_dependency(
  link_with: [
    libsynapse_lib
  ],
  include_directories: libsynapse_include_dir
)
