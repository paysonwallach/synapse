project(
  'com.paysonwallach.synapse',
  'vala',
  'c',
  license: ['GPL2', 'LGPL2.1'],
  meson_version: '>=0.50.0',
  version: '0.4.7'
)

i18n = import('i18n')
pkg = import('pkgconfig')
cc = meson.get_compiler('c')
vala = meson.get_compiler('vala')

vapi_dir = join_paths(meson.source_root(), 'vapi')

prefix = get_option('prefix')
lib_dir = join_paths(prefix, get_option('libdir'))
data_dir = join_paths(prefix, get_option('datadir'))
pkglib_dir = join_paths(lib_dir, meson.project_name())
plugins_dir = join_paths(pkglib_dir, 'plugins')

glib_version = '>=2.40.0'
gtk_version = '>=3.0.0'
gee_version = '>=0.5.2'
json_version = '>=0.10.0'
zeitgeist_version = '>=0.9.14'

gdk_dep = dependency('gdk-x11-3.0', version: gtk_version)
gee_dep = dependency('gee-0.8', version: gee_version)
gio_dep = dependency('gio-2.0', version: glib_version)
gio_unix_dep = dependency('gio-unix-2.0')
glib_dep = dependency('glib-2.0', version: glib_version)
glib_json_dep = dependency('json-glib-1.0', version: json_version)
gtk_dep = dependency('gtk+-3.0', version: gtk_version)
gmodule_dep = dependency('gmodule-2.0')
keybinder_dep = dependency('keybinder-3.0')
notify_dep = dependency('libnotify')
thread_dep = dependency('gthread-2.0')
m_dep = cc.find_library ('m', required : false)

# configuration file
conf = configuration_data()
conf.set_quoted('DATA_DIR', data_dir)
conf.set_quoted('PLUGINS_DIR', plugins_dir)
conf.set_quoted('APP_NAME', 'Synapse')
conf.set_quoted('APP_ID', meson.project_name())
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('RELEASE_NAME', 'Synapse')

if get_option('enable-indicator')
  indicator_dep = dependency('appindicator3-0.1',
    not_found_message: 'appindicator3-0.1 is not installed')
  indicator_vala_flags = '-D HAVE_INDICATOR'
  conf.set('HAVE_INDICATOR', 1, description: 'Have Indicator')
endif

if get_option('enable-zeitgeist')
  zeitgeist_dep = dependency('zeitgeist-2.0',
    version: zeitgeist_version,
    not_found_message: 'zeitgeist-2.0 is not installed')
  zeitgeist_vala_flags = ['--define', 'HAVE_ZEITGEIST']
  conf.set('HAVE_ZEITGEIST', 1, description: 'Have Zeitgeist')
endif

config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

config_inc_dir = include_directories('.')

config_dep = declare_dependency(
  dependencies: vala.find_library('config', dirs: vapi_dir),
  sources: config_h
)

common_vala_flags = [
    '--target-glib=2.40',
    '--vapidir=@0@'.format(vapi_dir),
  ]

add_project_arguments(
  common_vala_flags,
  language: 'vala',
)

add_project_arguments([
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DG_LOG_DOMAIN="@0@"'.format(meson.project_name())
  ],
  language: 'c'
)

subdir('data')
subdir('po')
subdir('lib')
subdir('src')
subdir('plugins')
