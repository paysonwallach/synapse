public class SearchEntry : Gtk.Entry {
    public const string[] size_to_string = {
        "xx-small",
        "x-small",
        "small",
        "medium",
        "large",
        "x-large",
        "xx-large"
    };

    public static Size string_to_size (string size_name) {
        Size s = Size.MEDIUM;

        for (uint i = 0 ; i < size_to_string.length ; i++) {
            if (size_to_string[i] == size_name)
                return (Size) i;
        }

        return s;
    }

    protected const double[] size_to_scale = {
        Pango.Scale.XX_SMALL,
        Pango.Scale.X_SMALL,
        Pango.Scale.SMALL,
        Pango.Scale.MEDIUM,
        Pango.Scale.LARGE,
        Pango.Scale.X_LARGE,
        Pango.Scale.XX_LARGE
    };

    public enum Size {
        XX_SMALL,
        X_SMALL,
        SMALL,
        MEDIUM,
        LARGE,
        X_LARGE,
        XX_LARGE
    }

    public bool natural_requisition {
        get; set; default = false;
    }

    public Size size {
        get; set; default = Size.MEDIUM;
    }

    private Size real_size = Size.MEDIUM;
    private Gtk.Requisition las_requisition;
}
