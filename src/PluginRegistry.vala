namespace Synapse {
    public class PluginRegistry : Object {
        private File plugin_directory;
        private Gee.List<PluginInfo> plugins;

        private static unowned PluginRegistry instance;

        public static PluginRegistry get_default () {
            return instance ?? new PluginRegistry ();
        }

        construct {
            instance = this;
            plugins = new Gee.ArrayList<PluginInfo> ();

            if (!Module.supported ()) {
                warning ("Modules are not supported on this platform");
                return;
            }

            debug (@"plugin dir: $(Config.PLUGINS_DIR)");
            plugin_directory = File.new_for_path (Config.PLUGINS_DIR);
            if (!plugin_directory.query_exists ())
                return;

            try {
                var enumerator = plugin_directory.enumerate_children (
                    string.join (",", FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_CONTENT_TYPE), 0);
                FileInfo info;
                while ((info = enumerator.next_file ()) != null) {
                    debug (@"found $(info.get_name ())");
                    if (info.get_content_type () == "application/x-sharedlib")
                        load_module (info.get_name ());
                }
            } catch (Error e) {
                warning (e.message);
            }

            try {
                plugin_directory.monitor_directory (FileMonitorFlags.NONE,
                                                    null).changed.connect ((file, other_file, type) => {
                    if (type == FileMonitorEvent.CREATED) {
                        load_module (file.get_basename ());
                    }
                });
            } catch (Error e) {
                warning (e.message);
            }
        }

        ~PluginRegistry () {
            instance = null;
        }

        public Gee.List<PluginInfo> get_plugins () {
            return plugins.read_only_view;
        }

        public PluginInfo? get_plugin_info_for_type (Type plugin_type) {
            foreach (PluginInfo pi in plugins) {
                if (pi.plugin_type == plugin_type) return pi;
            }

            return null;
        }

        private bool load_module (string plugin_name) {
            var path = Module.build_path (plugin_directory.get_path (), plugin_name);
            var module = Module.open (path, ModuleFlags.BIND_LOCAL);

            if (module == null) {
                warning (Module.error ());
                return false;
            }

            void * function;
            module.symbol ("register_plugin", out function);

            if (function == null) {
                warning ("%s failed to register: register_plugin() function not found", plugin_name);
                return false;
            }
            unowned RegisterPluginFunction register = (RegisterPluginFunction) function;

            var info = register ();

            if (info.plugin_type.is_a (typeof (Activatable)) == false) {
                warning ("%s does not return a class of type 'Activatable'", plugin_name);
                return false;
            }

            info.module_name = plugin_name;

            module.make_resident ();
            plugins.add (info);

            if (info.gettext_domain != null)
                Intl.bindtextdomain (info.gettext_domain,
                                     Path.build_filename (Config.DATA_DIR, "locale"));

            return true;
        }

    }
}
