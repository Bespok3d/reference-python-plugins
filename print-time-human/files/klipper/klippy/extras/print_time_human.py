"""Reference Klipper extra for ADR-0036: a Klipper extra that needs a third-party Python library.

The module is a plain, unmodified Klipper extra: it just `import humanize`. The library it needs is
declared in `klipper_requirements.txt`, baked into the plugin by CI, and symlinked into the system
site-packages by the daemon at install time, so Klipper's own interpreter can import it. The daemon
never pips into that interpreter; it only links a baked, net-new package. Deactivate/uninstall
remove the link.
"""
import humanize


class PrintTimeHuman:
    def __init__(self, config):
        self.printer = config.get_printer()
        gcode = self.printer.lookup_object("gcode")
        gcode.register_command(
            "PRINT_TIME_HUMAN",
            self.cmd_print_time_human,
            desc="Report the current print's elapsed time in plain words",
        )

    def cmd_print_time_human(self, gcmd):
        reactor = self.printer.get_reactor()
        print_stats = self.printer.lookup_object("print_stats")
        elapsed_seconds = print_stats.get_status(reactor.monotonic())["print_duration"]
        gcmd.respond_info(f"Elapsed: {humanize.naturaldelta(elapsed_seconds)}")


def load_config(config):
    return PrintTimeHuman(config)
