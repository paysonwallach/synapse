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
    public errordomain SearchError {
        SEARCH_CANCELLED,
        UNKNOWN_ERROR
    }

    public interface SearchProvider : Object {
        public abstract async Gee.List<Match> search (string query,
                                                      QueryFlags flags,
                                                      ResultSet? dest_result_set,
                                                      Cancellable? cancellable = null) throws SearchError;

    }
}
