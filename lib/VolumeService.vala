/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Michal Hruby <michal.mhr@gmail.com>
 */

namespace Synapse {
    public class VolumeService : GLib.Object {
        private static unowned VolumeService? instance;

        public static VolumeService get_default () {
            return instance ?? new VolumeService ();
        }

        private VolumeService () {}

        ~VolumeService () {
            instance = null;
        }

        private VolumeMonitor vm;
        private Gee.Map<GLib.Volume, VolumeObject> volumes;

        construct {
            instance = this;

            volumes = new Gee.HashMap<GLib.Volume, VolumeObject> ();

            initialize ();
        }

        protected void initialize () {
            vm = VolumeMonitor.get ();

            vm.volume_added.connect ((volume) => {
                volumes[volume] = new VolumeObject (volume);
            });
            vm.volume_removed.connect ((volume) => {
                volumes.unset (volume);
            });
            vm.mount_added.connect ((mount) => {
                var volume = mount.get_volume ();

                if (volume == null)
                    return;

                if (volume in volumes.keys)
                    volumes[volume].update_state ();
            });
            // FIXME: connect also to other signals?

            var volume_list = vm.get_volumes ();
            process_volume_list (volume_list);
        }

        private void process_volume_list (GLib.List<GLib.Volume> volume_list) {
            foreach (unowned GLib.Volume volume in volume_list) {
                volumes[volume] = new VolumeObject (volume);
            }
        }

        public Gee.Collection<VolumeObject> get_volumes () {
            return volumes.values;
        }

        public string? uri_to_volume_name (string uri, out string? volume_path) {
            volume_path = null;
            var g_volumes = volumes.keys;

            var f = File.new_for_uri (uri);
            // FIXME: cache this somehow
            foreach (var volume in g_volumes) {
                File? root = volume.get_activation_root ();

                if (root == null) {
                    var mount = volume.get_mount ();

                    if (mount == null)
                        continue;

                    root = mount.get_root ();
                }

                if (f.has_prefix (root)) {
                    volume_path = root.get_path ();

                    return volume.get_name ();
                }
            }

            return null;
        }

        public class VolumeObject : UriMatch {
            private ulong changed_signal_id;

            private GLib.Volume _volume;
            public GLib.Volume volume {
                get {
                    return _volume;
                }
                set {
                    _volume = value;
                    title = value.get_name ();
                    description = ""; // FIXME
                    icon_name = value.get_icon ().to_string ();
                    has_thumbnail = false;

                    if (value.get_mount () != null) {
                        uri = value.get_mount ().get_root ().get_uri ();
                        file_type = QueryFlags.PLACES;
                    } else {
                        uri = null;
                    }

                    if (changed_signal_id == 0)
                        changed_signal_id = _volume.changed.connect (this.update_state);

                    debug ("vo[%p]: %s [%s], has_mount: %d, uri: %s", this, title, icon_name, (value.get_mount () != null ? 1 : 0), uri);
                }
            }

            public void update_state () {
                this.volume = _volume;
            }

            public bool is_mounted () {
                return _volume.get_mount () != null;
            }

            public VolumeObject (GLib.Volume volume) {
                Object (volume: volume);
            }

            ~VolumeObject () {
                if (changed_signal_id != 0) {
                    // FIXME: the following commented line leads to lock up,
                    // the line beneath it is a possible fix (?)
                    // SignalHandler.disconnect (_volume, changed_signal_id);
                    _volume.disconnect (changed_signal_id);

                    changed_signal_id = 0;
                }
            }

        }
    }
}
