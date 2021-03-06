/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
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
    public interface Activatable : Object {
        // this property will eventually go away
        public abstract bool enabled { get; set; default = true; }

        public abstract void activate ();
        public abstract void deactivate ();

    }

    public interface Configurable : Object {
        public abstract Gtk.Widget create_config_widget ();

    }

    public interface ItemProvider : Activatable {
        public abstract async ResultSet? search (Query query) throws SearchError;
        public virtual bool handles_query (Query query) {
            return true;
        }

        public virtual bool handles_empty_query () {
            return false;
        }

    }

    public interface ActionProvider : Activatable {
        public abstract ResultSet? find_for_match (ref Query query, Match match);
        public virtual bool handles_unknown () {
            return false;
        }

    }

    // don't move into a class, gir doesn't like it
    [CCode (has_target = false)]
    public delegate PluginInfo RegisterPluginFunction ();

    public class PluginInfo {
        public Type plugin_type;
        public string title;
        public string description;
        public string icon_name;
        public string? gettext_domain;
        public string module_name;
        public bool runnable;
        public string runnable_error;
        public PluginInfo (Type type, string title, string description,
                           string icon_name, string? gettext_domain,
                           bool runnable, string runnable_error) {
            this.plugin_type = type;
            this.title = title;
            this.description = description;
            this.icon_name = icon_name;
            this.gettext_domain = gettext_domain;
            this.runnable = runnable;
            this.runnable_error = runnable_error;
        }

    }
}
