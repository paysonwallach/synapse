namespace Synapse.Gui {
    public class ViewPantheon : Synapse.Gui.View {
        static construct {
            var icon_size = new ParamSpecInt (
                "icon-size",
                "Icon Size",
                "The size of focused icon in supported themes",
                24, 64, 48,
                ParamFlags.READWRITE
                );
            var title_max = new ParamSpecString (
                "title-size",
                "Title Font Size",
                "The standard size of a match title in Pango absolute sizes (string)",
                "large",
                ParamFlags.READWRITE
                );
            var description_max = new ParamSpecString (
                "description-size",
                "Description Font Size",
                "The standard size of a match description in Pango absolute sizes (string)",
                "medium",
                ParamFlags.READWRITE
                );

            install_style_property (icon_size);
            install_style_property (title_max);
            install_style_property (description_max);
        }

        public override void style_updated () {
            base.style_updated ();

            int width, icon_size;
            string title_max, description_max;

            style_get (
                "ui-width", out width, "icon-size", out icon_size,
                "title-size", out title_max, "description-size", out description_max
                );

            overlay.set_size_request (width, -1);
            fix_listview_size (results_sources.get_match_renderer (), icon_size,
                               title_max, description_max);
            fix_listview_size (results_actions.get_match_renderer (), icon_size,
                               title_max, description_max);
            fix_listview_size (results_targets.get_match_renderer (), icon_size,
                               title_max, description_max);
        }

        private Gtk.Overlay overlay;
        // private Gtk.Grid grid;
        private Gtk.Box container;
        private Gtk.Box action_box;
        private Gtk.Box target_box;

        // private SmartLabel status;
        private SmartLabel search_label;

        private SpecificMatchList results_sources;
        private SpecificMatchList results_actions;
        private SpecificMatchList results_targets;

        private MenuThrobber menu_throbber;

        protected override void build_ui () {
            overlay = new Gtk.Overlay ();
            container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            search_label = new SmartLabel ();
            search_label.set_animation_enabled (true);
            search_label.set_ellipsize (Pango.EllipsizeMode.END);
            search_label.size = SmartLabel.Size.XX_LARGE;
            search_label.margin_start = 3;

            container.pack_start (search_label, false, false, 2);

            menu_throbber = new MenuThrobber ();
            menu = (MenuButton) menu_throbber;

            menu_throbber.set_size_request (14, 14);
            menu_throbber.halign = Gtk.Align.END;

            overlay.add_overlay (menu_throbber);

            results_sources = new SpecificMatchList (controller, model, SearchingFor.SOURCES);
            results_actions = new SpecificMatchList (controller, model, SearchingFor.ACTIONS);
            results_targets = new SpecificMatchList (controller, model, SearchingFor.TARGETS);

            connect_handlers (results_sources);
            connect_handlers (results_actions);
            connect_handlers (results_targets);

            results_sources.use_base_colors = false;
            results_actions.use_base_colors = false;
            results_targets.use_base_colors = false;

            fix_listview_size (results_sources.get_match_renderer ());
            fix_listview_size (results_actions.get_match_renderer ());
            fix_listview_size (results_targets.get_match_renderer ());

            container.pack_start (results_sources);
            container.pack_start (create_separator (), false);

            action_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            action_box.pack_start (results_actions, false);
            action_box.pack_start (create_separator (), false);
            container.pack_start (action_box, false);

            target_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            target_box.pack_start (results_targets, false);
            target_box.pack_start (create_separator (), false);
            container.pack_start (action_box, false);

            overlay.add (container);
            overlay.show_all ();

            overlay.set_size_request (500, -1);
            this.add (overlay);
        }

        private Gtk.Widget create_separator () {
            var separator = new Gtk.EventBox ();

            separator.height_request = 2;
            separator.width_request = 120;

            var style_context = separator.get_style_context ();

            style_context.add_class (Gtk.STYLE_CLASS_SEPARATOR);
            style_context.add_class (Gtk.STYLE_CLASS_HORIZONTAL);
            separator.draw.connect (draw_separator);

            return separator;
        }

        private bool draw_separator (Gtk.Widget separator, Cairo.Context context) {
            separator.get_style_context ().render_frame (context, 0, 0,
                                                         separator.get_allocated_width (), 2);
            return false;
        }

        private void fix_listview_size (MatchViewRenderer renderer, int icon_size = 48, string title = "large", string description = "medium") {
            renderer.icon_size = icon_size;
            renderer.title_markup = "<span size=\"%s\"><b>%%s</b></span>".printf (title);
            renderer.description_markup = "<span size=\"%s\">%%s</span>".printf (description);
        }

        public override bool is_list_visible () {
            return true;
        }

        public override void set_list_visible (bool visible) {
            if (this.visible)
                return;
            results_sources.min_visible_rows = visible ? 7 : 1;
        }

        public override void set_throbber_visible (bool visible) {
            menu_throbber.active = visible;
        }

        public override void update_searching_for () {
            results_sources.update_searching_for ();
            results_actions.update_searching_for ();
            results_targets.update_searching_for ();

            target_box.visible = results_targets.min_visible_rows > 0;

            update_labels ();
        }

        public void update_labels () {
            var focus = model.get_actual_focus ();

            if (focus.value == null) {
                if (controller.is_in_initial_state ()) {
                    search_label.set_opacity (0.4);
                    search_label.set_text (IController.TYPE_TO_SEARCH);
                }
            } else {
                search_label.set_markup (
                    @"$(Markup.escape_text (model.query[model.searching_for]))<span foreground='grey'> – $(Markup.escape_text  (focus.value.title))</span>");
                search_label.set_opacity (1.0);
            }

            if (model.has_results ()) {
                results_sources.visible = true;
            } else {
                results_sources.visible = false;
            }
        }

        protected override void paint_background (Cairo.Context ctx) {
            Gtk.Allocation container_allocation;
            overlay.get_allocation (out container_allocation);

            int width = container_allocation.width + BORDER_RADIUS * 2;
            int height = container_allocation.height + BORDER_RADIUS * 2;
            ctx.translate (container_allocation.x - BORDER_RADIUS, container_allocation.y - BORDER_RADIUS);
            if (this.is_composited ()) {
                ctx.translate (0.5, 0.5);
                ctx.set_operator (Cairo.Operator.OVER);
                Utils.cairo_make_shadow_for_rect (ctx, 0, 0, width - 1, height - 1,
                                                  BORDER_RADIUS, 0, 0, 0, SHADOW_SIZE);
                ctx.translate (-0.5, -0.5);
            }
            ctx.save ();
            // pattern
            Cairo.Pattern pat = new Cairo.Pattern.linear (0, 0, 0, height);
            ch.add_color_stop_rgba (pat, 0.0, 0.95, StyleType.BG, Gtk.StateFlags.NORMAL, Mod.LIGHTER);
            ch.add_color_stop_rgba (pat, 0.2, 1.0, StyleType.BG, Gtk.StateFlags.NORMAL, Mod.NORMAL);
            ch.add_color_stop_rgba (pat, 1.0, 1.0, StyleType.BG, Gtk.StateFlags.NORMAL, Mod.DARKER);
            Utils.cairo_rounded_rect (ctx, 0, 0, width, height, BORDER_RADIUS);
            ctx.set_source (pat);
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.clip ();
            ctx.paint ();
            ctx.restore ();
        }

        public override void update_focused_source (Entry<int, Match> m) {
            if (m.value != null)
                results_sources.set_indexes (m.key, m.key);

            if (model.searching_for == SearchingFor.SOURCES)
                update_labels ();
        }

        public override void update_focused_action (Entry<int, Match> m) {
            if (m.value != null)
                results_actions.set_indexes (m.key, m.key);

            if (model.searching_for == SearchingFor.ACTIONS)
                update_labels ();
        }

        public override void update_focused_target (Entry<int, Match> m) {
            if (m.value != null)
                results_targets.set_indexes (m.key, m.key);

            if (model.searching_for == SearchingFor.TARGETS)
                update_labels ();
        }

        public override void update_sources (Gee.List<Match>? list = null) {
            results_sources.set_list (list);

            action_box.visible = !controller.is_in_initial_state ();
        }

        public override void update_actions (Gee.List<Match>? list = null) {
            results_actions.set_list (list);
        }

        public override void update_targets (Gee.List<Match>? list = null) {
            results_targets.set_list (list);
            results_targets.update_searching_for ();

            target_box.visible = results_targets.min_visible_rows > 0;
        }

    }
}
