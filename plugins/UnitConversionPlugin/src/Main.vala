/*
 * Copyright (c) 2018 Peter Uithoven <peter@peteruithoven.nl>
 *               2018 elementary LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Peter Uithoven <peter@peteruithoven.nl>
 */

namespace Synapse {
    public class ConversionPlugin : Object, Activatable, ItemProvider {
        public bool enabled { get; set; default = true; }

        public void activate () {}
        public void deactivate () {}

        private class Result : TextMatch {
            public int default_relevancy { get; set; default = MatchScore.INCREMENT_MINOR; }
            public string query_template { get; construct set; }

            public Result (string result, string result_expression) {
                Object (
                    title: result,
                    description: result_expression,
                    has_thumbnail: false,
                    icon_name: "accessories-calculator"
                    );
            }

            public override string get_text () {
                return title;
            }

        }

        private Regex regex;

        construct {
            /* The regex describes a string which *resembles* a unit conversion expression.
               Basically it matches strings of the form:
               "number unit to unit"
             */
            try {
                regex = new Regex ("^(-?\\d+([.,]\\d+)?)\\s*([\\w/]+)\\s+(to)\\s+([\\w/]+)$", RegexCompileFlags.OPTIMIZE);
            } catch (Error e) {
                critical ("Error creating regexp: %s", e.message);
            }
        }

        public bool handles_query (Query query) {
            return (QueryFlags.ACTIONS in query.query_type);
        }

        public async ResultSet? search (Query query) throws SearchError {
            var results = new ResultSet ();
            var input = query.query_string;

            if (regex.match (input)) {
                try {
                    var command = get_command (input);
                    var subprocess = new Subprocess.newv (command, SubprocessFlags.STDOUT_PIPE);
                    var output = get_output (subprocess);

                    if (yield subprocess.wait_check_async ()) {
                        var output_split = output.split ("=");
                        var result_string = output_split[1].strip ();
                        var result = new Result (result_string, output);

                        results.add (result, MatchScore.EXCELLENT);
                    }
                } catch (Error e) {
                    if (!query.is_cancelled ())
                        error ("error: %s\n", e.message);
                }
            }

            query.check_cancellable ();

            return results;
        }

        private string[] get_command (string query) {
            var array = new GenericArray<string> ();
            array.add ("qalc");
            array.add (query);
            return array.data;
        }

        private string get_output (Subprocess subprocess) {
            unowned InputStream stdout_stream = subprocess.get_stdout_pipe ();
            var stdout_datastream = new DataInputStream (stdout_stream);
            var stdout_text = "";
            var stdout_line = "";

            while ((stdout_line = stdout_datastream.read_line (null)) != null) {
                stdout_text += stdout_line + "\n";
            }

            return stdout_text.strip ();
        }

    }
}

public Synapse.PluginInfo register_plugin () {
    return new Synapse.PluginInfo (
        typeof (Synapse.ConversionPlugin),
        _("Conversion"),
        _("Unit conversion."),
        "accessories-calculator",
        null,
        Environment.find_program_in_path ("qalc") != null,
        _("qalc is not installed")
        );
}
