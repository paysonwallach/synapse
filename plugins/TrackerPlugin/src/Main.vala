/*
 * Copyright (c) 2020 Payson Wallach <payson@paysonwallach.com>
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
 */

namespace Synapse {
    private class TrackerUriMatch : UriMatch {
        public TrackerUriMatch (string? _title, string? _description, string? _icon_name, string? _thumbnail_path, string? _uri, string? _mime_type) {
            Object (
                title: _title ?? Path.get_basename (_uri ?? ""),
                description: _description,
                icon_name: _icon_name,
                thumbnail_path: _thumbnail_path,
                uri: _uri,
                mime_type: _mime_type
                );
        }

    }

    public class TrackerPlugin : Object, Activatable, ItemProvider {
        public const string UNIQUE_NAME = "org.freedesktop.Tracker1";

        private enum MatchFields {
            URI,
            TITLE,
            MIME_TYPE,
            N_FIELDS
        }

        private static string interesting_attributes =
            string.join (",", FileAttribute.STANDARD_TYPE,
                         FileAttribute.STANDARD_ICON,
                         FileAttribute.THUMBNAIL_PATH,
                         FileAttribute.STANDARD_IS_HIDDEN,
                         null);

        private Tracker.Sparql.Connection connection;

        public bool enabled { get; set; default = true; }

        public void activate () {
            try {
                debug ("getting connection...");
                connection = Tracker.Sparql.Connection.@get ();
                // connection = Tracker.Sparql.Connection.local_new (Tracker.Sparql.ConnectionFlags.READONLY, File.new_for_path("/home/paysonwallach/.cache/tracker"), null, null, null);
                // statement = connection.query_statement ("SELECT tracker:coalesce (nie:url (?s), ?s) nie:title (?s) nie:mimeType (?s) ?type WHERE {  ?s fts:match ~foo ;  rdf:type ?type . } GROUP BY nie:url(?s) ORDER BY nie:url(?s) LIMIT 96");
            } catch (Error error) {
                warning (error.message);
            }
        }

        public void deactivate () {
            connection = null;
        }

        private static int compute_relevancy (string uri, int base_relevancy) {
            var rs = RelevancyService.get_default ();
            float pop = rs.get_uri_popularity (uri);

            return RelevancyService.compute_relevancy (base_relevancy, pop);
        }

        private async TrackerUriMatch? process_result (Tracker.Sparql.Cursor cursor) {
            string uri = cursor.get_string (MatchFields.URI);
            if (uri == null)
                return null;
            debug ("processing result...");
            string title = cursor.get_string (MatchFields.TITLE);
            string mime_type = cursor.get_string (MatchFields.MIME_TYPE);
            string description = uri.split ("://")[1].replace ("%20", " ");
            string icon_name = null;
            string thumbnail_path = null;
            var file = File.new_for_uri (uri);

            if (title == null)
                title = file.get_basename ();

            if (file.get_uri_scheme () != "data" && file.is_native ()) {
                try {
                    var file_info = yield file.query_info_async (interesting_attributes, 0, 0, null);

                    icon_name = file_info
                                 .get_icon ()
                                 .to_string ();

                    if (file_info.has_attribute (FileAttribute.THUMBNAIL_PATH))
                        thumbnail_path = file_info.get_attribute_byte_string (FileAttribute.THUMBNAIL_PATH);
                } catch (Error error) {
                    warning (@"$(error.message)");
                }
            }

            debug (@"creating new match: $title\n$uri");
            return new TrackerUriMatch (title, description, icon_name, thumbnail_path, uri, mime_type);
        }

        uint timeout = 0U;
        public async ResultSet? search (Query query) throws SearchError {
            if (query.query_string.length < 2)
                return null;

            var call_now = timeout != 0U;

            if (timeout != 0U)
                Source.remove (timeout);

            timeout = Timeout.add (
                200,
                () => {
                if (timeout != 0U) {
                    Source.remove (timeout);
                    timeout = 0U;

                    return Source.REMOVE;
                }
                return Source.CONTINUE;
            });

            if (!call_now)
                return null;

            var results = new ResultSet ();

            debug ("constructing query...");
            var query_string =
                "SELECT tracker:coalesce (nie:url (?s), ?s) nie:title (?s) nie:mimeType (?s) ?type WHERE {  ?s fts:match \"%s\" ;  rdf:type ?type . } GROUP BY nie:url(?s) ORDER BY nie:url(?s) LIMIT %u"
                 .printf (
                    Tracker.Sparql.escape_string (query.query_string.strip ()), query.max_results);

            try {
                debug ("querying...");
                var cursor = yield connection.query_async (query_string, query.cancellable);

                var next = false;

                do {
                    int relevancy = MatchScore.AVERAGE;

                    debug ("getting result...");
                    try {
                        next = yield cursor.next_async (query.cancellable);

                    } catch (Error err) {
                        warning (err.message);
                    }

                    debug ("processing result...");
                    var result = yield process_result (cursor);

                    if (result != null) {
                        if (result.uri != null)
                            relevancy = compute_relevancy (result.uri, MatchScore.AVERAGE);

                        debug (@"adding result with relevancy $relevancy...");
                        results.add (result, relevancy);
                    }
                } while (next && !query.is_cancelled ());
            } catch (Error error) {
                warning (error.message);
                // warning (@"failed to execute \"$(statement.sparql)\"");
            }

            query.check_cancellable ();

            return results;
        }
    }
}

public Synapse.PluginInfo register_plugin () {
    Synapse.PluginInfo plugin_info = null;
    var dbus_service = Synapse.DBusService.get_default ();
    var loop = new MainLoop ();

    dbus_service.name_is_activatable_async.begin (
        Synapse.TrackerPlugin.UNIQUE_NAME, (obj, res) => {
        var activatable = dbus_service.name_is_activatable_async.end (res);
        plugin_info = new Synapse.PluginInfo (
            typeof (Synapse.TrackerPlugin),
            "Tracker",
            "",
            "",
            null,
            activatable,
            ""
            );

        loop.quit ();
    });
    loop.run ();

    return plugin_info;
}
