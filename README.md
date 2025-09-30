
 +# Nymph
    
    Nymph is a lightweight “fetch” style utility written in Nim that shows a
    colourful Kitty-graphics logo alongside key system details (OS, kernel,
    packages, shell, uptime, memory).
    
    ## Features
    
    - **Autodetected distro logos**: automatically selects the best matching
      `.kitty` file based on `/etc/os-release` (`ID`, `ID_LIKE`, `NAME`,
      `PRETTY_NAME`).
    - **Runtime overrides**: choose a logo with `--logo=NAME` or the
      `NYMPH_LOGO` environment variable; add custom search paths with
      `NYMPH_LOGO_DIR`.
    - **Accurate stats**: pulls package counts from the relevant package manager
      metadata (including correct handling of APT’s `Status: install ok
      installed`).
    - **Pure Nim + Kitty protocol**: no heavyweight dependencies or extra assets
      required beyond the shipped `.kitty` graphics.
    
    ## Building
    
    ```bash
    # ensure Nim/nimble are available
    nimble build        # release build (default target src/nymph)
    # or
    nim c -r src/nymph.nim
    ```
    
    The compiled binary lives at `src/nymph`.
    
    ## Usage
    
    ```bash
    ./nymph [--logo NAME]
    ```
    
    Options/Environment:
    
    - `--logo NAME` / `-logo NAME` — force use of `NAME.kitty`.
    - `NYMPH_LOGO` — alternative override (`NYMPH_LOGO=fu ./nymph`).
    - `NYMPH_LOGO_DIR` — prepend a directory to the logo search order.
    
    Logo search order:
    
    1. `$NYMPH_LOGO_DIR`
    2. `<executable dir>/logos`
    3. `<executable dir>/../share/nymph/logos`
    4. `src/assets/logos`
    5. `assets/logos`
    
    If no file is found for the requested name, Nymph falls back to
    `generic.kitty`.
    
    ## Adding Logos
    
    Drop additional `NAME.kitty` files (Kitty graphics sequences) into any of the
    search locations above. Nymph automatically picks them up and will match them
    against distro IDs or your overrides.
    
    ## Example
    
    ```bash
    # autodetected logo based on /etc/os-release
    ./nymph
    
    # force a specific logo
    ./nymph --logo=fu
    
    # use custom logo directory under ~/.local/share
    NYMPH_LOGO_DIR=~/.local/share/nymph/logos ./nymph
    ```
    
    ## License
    
    MIT — see `LICENSE`.