install_data(
  'synapse.svg',
  install_dir: join_paths(data_dir, 'icons', 'hicolor', 'scalable', 'apps')
)

i18n.merge_file(
  input: 'synapse.desktop.in',
  output: 'synapse.desktop',
  po_dir: join_paths(meson.source_root(), 'po', 'extra'),
  type: 'desktop',
  install: true,
  install_dir: join_paths(data_dir, 'applications')
)
