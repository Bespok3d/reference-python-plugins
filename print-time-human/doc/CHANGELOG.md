# Changelog

## 0.1.1

- Ship the `[print_time_human]` config include that loads the extra, so the
  PRINT_TIME_HUMAN command is registered. Without it Klipper never imported the
  module and the command was unknown.

## 0.1.0

- First release. Reference plugin: a Klipper extra whose pure-Python dependency
  is baked into the package and linked into the Klipper interpreter, with no pip
  ever running on the printer.
- Experimental: serves as a worked example for plugin authors.
