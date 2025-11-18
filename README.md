Nymph is a tiny, lightweight “fetch” utility written in Nim.

## Screenshot

   ![Nymph](Nymph.png)

## Features

- Kitty graphics protocol support: drop a PNG logo in the `logos/` directory (or `$NYMPH_LOGO_DIR`) and it will render in terminals that support the kitty graphical protocol.
- Built-in ASCII fallback logo, so output still looks good on terminals without Kitty graphics protocol support.
- Reasonable defaults: automatically selects a logo based on `/etc/os-release`, `$NYMPH_LOGO`, or falls back to the generic art.

## Usage

1. Install Nim/nimble.
2. Build and run:
   ```bash
   nimble release
   ```
   or 
   ```bash
   nim c -r src/nymph.nim
   ```
3. Optional CLI/env overrides:
   - `--logo foo` / `-logo foo` forces a specific logo name.
   - `NYMPH_LOGO=foo` or `NYMPH_LOGO_DIR=/path/to/logos` change selection/search paths.

integrate it into shell startup scripts or keybindings as you like.

## Logos

- **PNG logos**: Place files named `<name>.png` inside any of the following (searched in order):
  1. `$NYMPH_LOGO_DIR`
  2. `<app_dir>/logos` and `<app_dir>/../share/nymph/logos`
  3. Source `logos/`
  4. Project `logos/`
- **Requirements**: PNG files render best at 128×128 px. Nymph uses the Kitty graphics protocol; PNG logos only appear in Kitty terminals.
- **Scaling**: PNG logos are self-scaling up to 128×128 px.
- **Fallback**: If no PNG is found or Kitty graphics protocol aren’t available, Nymph displays the built-in ASCII “generic” logo.

## License

MIT — see `LICENSE`.
