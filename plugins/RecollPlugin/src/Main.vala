/*
 *
 * Authored by Patrick Marchwiak <pd@marchwiak.com>
 *
 */

namespace Synapse {
    private class RecollUriMatch : UriMatch {
        public RecollUriMatch (string? _title, string? _description, string? _icon_name, string? _thumbnail_path, string? _uri, string? _mime_type) {
            Object (
                title: _title,
                description: _description,
                icon_name: _icon_name ?? "recoll",
                thumbnail_path: _thumbnail_path,
                uri: _uri,
                mime_type: _mime_type
                );
        }

    }

    public class RecollPlugin : Object, Activatable, ItemProvider {
        public bool enabled { get; set; default = true; }

        public void activate () {}

        public void deactivate () {}

        enum LineType {
            FIELDS,
            ABSTRACT_START,
            ABSTRACT,
            ABSTRACT_END;
        }

        private static string interesting_attributes =
            string.join (",", FileAttribute.STANDARD_TYPE,
                         FileAttribute.STANDARD_ICON,
                         FileAttribute.THUMBNAIL_PATH,
                         FileAttribute.STANDARD_IS_HIDDEN,
                         null);

        private async void fetch_result_from_output (DataInputStream output, out RecollUriMatch result, out int relevancy_penalty) throws SearchError {
            relevancy_penalty = 0;

            var @continue = true;
            var next_line_type = LineType.FIELDS;

            string? line = null;
            string? title = null;
            string? description = null;
            string? icon_name = null;
            string? thumbnail_path = null;
            string? uri = null;
            string? mime_type = null;

            try {
                while (continue && (line = yield output.read_line_async (Priority.DEFAULT)) != null) {
                    switch (next_line_type) {
                    case LineType.FIELDS:
                        string[] fields = line.split ("\t");

                        uri = fields[1];
                        title = fields[2];
                        title = title.substring (1, title.length - 2);
                        description = uri.split ("://")[1];
                        uri = uri
                               .substring (1, uri.length - 2);
                        mime_type = fields[0];

                        var file = File.new_for_uri (uri);

                        if (file.get_uri_scheme () != "data" && file.is_native ()) {
                            try {
                                var file_info = yield file.query_info_async (interesting_attributes, 0, 0, null);

                                icon_name = file_info
                                             .get_icon ()
                                             .to_string ();

                                if (file_info.has_attribute (FileAttribute.THUMBNAIL_PATH))
                                    thumbnail_path = file_info.get_attribute_byte_string (FileAttribute.THUMBNAIL_PATH);

                                if (file_info.get_is_hidden ())
                                    relevancy_penalty += MatchScore.INCREMENT_MEDIUM;
                            } catch (Error error) {
                                warning (@"$(error.message)");
                            }
                        }

                        next_line_type = LineType.ABSTRACT_START;
                        break;
                    case LineType.ABSTRACT_START:
                        if (line.chug ().chomp () == "ABSTRACT")
                            next_line_type = LineType.ABSTRACT;
                        break;
                    case LineType.ABSTRACT:
                        line = line.chug ().chomp ();

                        if (line != null && line != "")
                            description = @"$description: $line";

                        next_line_type = LineType.ABSTRACT_END;
                        break;
                    case LineType.ABSTRACT_END:
                        if (line.chug ().chomp () == "/ABSTRACT") {
                            result = new RecollUriMatch (
                                title,
                                description,
                                icon_name,
                                thumbnail_path,
                                uri,
                                mime_type
                                );
                            @continue = false;
                        }
                        break;
                    default:
                        assert_not_reached ();
                    }
                }
            } catch (Error error) {
                warning (@"$(error.message)");
            }
        }

        public async ResultSet? search (Query query) throws SearchError {
            Pid pid;
            int read_fd, write_fd;
            string[] argv = { "recoll",
                              "-t", // command line mode
                              "-n", // indices of results
                              "0-20", // return first 20 results
                              "-a", // ALL TERMS mode
                              "-A", // output abstracts
                              query.query_string };
            var results = new ResultSet ();

            try {
                Process.spawn_async_with_pipes (null, argv, null,
                                                SpawnFlags.SEARCH_PATH,
                                                null, out pid, out write_fd, out read_fd);
                UnixInputStream read_stream = new UnixInputStream (read_fd, true);
                DataInputStream recoll_output = new DataInputStream (read_stream);

                /*
                 * Sample output from `recoll -t ...`:
                 *
                 *   Recoll query: ((kernel:(wqf=11) OR kernels OR kernelize OR kernelized))
                 *   4725 results (printing  1 max):
                 *   text/plain	[file:///home/patrick/code/sample-results.txt]	[sample-results.txt]	8806	bytes
                 *   ABSTRACT
                 *   some text summarizing the document usually has the keyword (kernel)
                 *   /ABSTRACT
                 *
                 */
                var results_count = 0;

                string line;
                for (int i = 0 ; i < 2 ; i++) {
                    if ((line = yield recoll_output.read_line_async (Priority.DEFAULT)) != null && i > 0) { // skip query synopsis
                        results_count = int.min (int.parse (line.split (" ")[0]), 96);
                    }
                }

                for (int i = 0 ; i < results_count ; i++) {
                    int relevancy_penalty;
                    RecollUriMatch result;

                    yield fetch_result_from_output (recoll_output, out result, out relevancy_penalty);

                    if (result != null)
                        results.add (
                            result,
                            MatchScore.AVERAGE
                            + ((results_count - i) / results_count * MatchScore.INCREMENT_MINOR)
                            - relevancy_penalty);

                    query.check_cancellable ();
                }
            } catch (Error err) {
                if (!query.is_cancelled ()) warning ("%s", err.message);
            }

            return results;
        }
    }
}

public Synapse.PluginInfo register_plugin () {
    return new Synapse.PluginInfo (
        typeof (Synapse.RecollPlugin),
        _("Recoll"),
        _("Returns results of full text search against an existing Recoll index."),
        "recoll",
        null,
        Environment.find_program_in_path ("recoll") != null,
        _("recoll is not installed")
        );
}
