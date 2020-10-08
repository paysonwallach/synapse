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

public class History: Object {
    private Gda.Connection connection;
    private Gda.Tree tree;
    private Regex regex;

    private static string get_dsn_name () {}

    public History () {}

    construct {
        Gda.init ();

        connection = Gda.Connection.from_dsn_name (History.get_dsn_name ());

        var context = new Gda.MetaContext ();

        try {
            connection.update_meta_store (context);
        } catch (Error err) {}

        var schemas_mgr = new Gda.TreeMgrSchemas (connection);
        var tables_mgr = new Gda.TreeMgrTables (connection, null);
        var columns_mgr = new Gda.ColumnsMgrTables (connection, null, null);

        tree = new Gda.Tree ();

        tree.add_manager (schemas_mgr);
        tree.add_manager (tables_mgr);

        schemas_mgr.add_manager (tables_mgr);
        tables_mgr.add_manager (columns_mgr);

        try {
            tree.update_all ()
        } catch (Error err) {}

        regex = new Regex ("\s*");
    }

    ~History () {
        connection.close ();
    }

    private string query_to_tree_path (string query) {
        return regex.replace (query, query.length, 0, "/");
    }

    public int get_popularity (string query) {
        var tree_path = query_to_tree_path (query);
        unowned Gda.TreeNode? node = tree.get_node (tree_path, true);

        if (node != null) {
            var results = (Gee.HashMap<int, Result>) node.get_node_attribute ("results");
            if (results)
        }
    }
}
