public class CLITerm : Gtk.Window
{
    private MWSerial s;
    private MWSerial.ProtoMode oldmode;
    private Vte.Terminal term;
    public signal void on_exit();

    public CLITerm (Gtk.Window? w = null)
    {
        this.modal = true;
        if(w != null)
        {
            this.set_transient_for (w);
        }
        this.title = "mwp CLI";
        this.window_position = Gtk.WindowPosition.CENTER;
        this.destroy.connect (() => {
                uint8 c[1] = {4};
                s.write(c, 1);
                s.pmode = oldmode;
                on_exit();
            });
        this.set_default_size (640, 400);

        term = new Vte.Terminal();

        // bcol="#002B36", fcol="#839496"
        Gdk.RGBA bcol = {0, 0.168627, 0.21176};
        Gdk.RGBA fcol = {0.513725, 0.580392, 0.588235};

        term.set_color_background(bcol);
        term.set_color_foreground(fcol);

        term.commit.connect((text,size) =>
            {
                switch(text[0])
                {
                    case 3:
                        this.destroy();
                        break;
                    case 8:
                    uint8 c[1] = {127};
                        s.write(c,1);
                        break;
                    case 27:
                        break;
                    default:
                        s.write(text.data, size);
                    break;
                }
            });
        this.add (term);
    }

    public void configure_serial (MWSerial _s)
    {
        s = _s;
        oldmode  =  s.pmode;
        s.pmode = MWSerial.ProtoMode.CLI;
        s.cli_event.connect((buf,len) => {
                buf[len] = 0;
                term.feed(buf[0:len]);
                if(((string)buf).contains("Rebooting"))
                    term.feed("\r\n\n\x1b[1mEither close this window or type # to re-enter the CLI\x1b[0m\r\n".data);
            });
        uint8 c[1] = {'#'};
        s.write(c, 1);
    }

}
