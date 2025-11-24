import std/[os, strutils]

type
  RuntimeConfig* = object
    maxLogoWidth*: int
    statsOffset*: int
    configLogoDir*: string
    customLogoFile*: string
    noColor*: bool

const
  DefaultMaxLogoWidth* = 200
  DefaultStatsOffsetBase* = 22

proc normalizeDir*(path: string): string =
  ## Expand ~ and return an absolute path with duplicate separators removed.
  if path.len == 0:
    return ""

  var expanded = path
  if expanded[0] == '~':
    let home = getHomeDir()
    if home.len > 0:
      if expanded.len == 1:
        expanded = home
      else:
        var suffix = expanded[1 .. expanded.high]
        if suffix.len > 0 and (suffix[0] == DirSep or suffix[0] == '/'):
          if suffix.len > 1:
            suffix = suffix[1 .. suffix.high]
          else:
            suffix = ""
        expanded = home / suffix

  if isAbsolute(expanded): expanded else: absolutePath(expanded)


proc defaultConfig*(): RuntimeConfig =
  RuntimeConfig(
    maxLogoWidth: DefaultMaxLogoWidth,
    statsOffset: DefaultStatsOffsetBase,
    configLogoDir: "",
    customLogoFile: "",
    noColor: false
  )

proc configPaths(): seq[string] =
  let envCfg = getEnv("NYMPH_CONFIG")
  if envCfg.len > 0: result.add envCfg
  let xdg = getEnv("XDG_CONFIG_HOME")
  if xdg.len > 0:
    result.add normalizeDir(xdg / "nymph" / "config.conf")
  else:
    result.add normalizeDir(getHomeDir() / ".config" / "nymph" / "config.conf")
  result.add "/etc/xdg/nymph/config.conf"


proc loadConfig*(): RuntimeConfig =
  ## Load config from simple key=value lines; create defaults if missing.
  result = defaultConfig()
  var found = false

  for path in configPaths():
    if not fileExists(path): continue
    try:
      for rawLine in lines(path):
        var line = rawLine.strip()
        if line.len == 0 or line.startsWith("#"): continue
        let hashPos = line.find('#')
        if hashPos >= 0:
          line = line[0 ..< hashPos].strip()
          if line.len == 0: continue
        let parts = line.split("=", 1)
        if parts.len != 2: continue
        let key = parts[0].strip().toLowerAscii()
        var val = parts[1].strip()
        val = val.strip(chars = {' ', '"'})
        case key
        of "maxwidth":
          try:
            let v = val.parseInt()
            if v > 0: result.maxLogoWidth = v
          except ValueError:
            discard
        of "statsoffset":
          try:
            let v = val.parseInt()
            if v > 0: result.statsOffset = v
          except ValueError:
            discard
        of "customlogo":
          if val.len > 0: result.customLogoFile = val
        of "nocolor":
          result.noColor = val.toLowerAscii() in ["1", "true", "yes", "on"]
        else:
          discard
      found = true
    except IOError:
      discard

  let homeCfg = normalizeDir(getHomeDir() / ".config" / "nymph")
  if not found:
    try:
      if not dirExists(homeCfg): createDir(homeCfg)
      let logoDir = homeCfg / "logos"
      if not dirExists(logoDir): createDir(logoDir)
      result.configLogoDir = logoDir
      let path = homeCfg / "config.conf"
      if not fileExists(path):
        let content = "# Nymph configuration (key=value)\n" &
                      "maxwidth = " & $result.maxLogoWidth & "\n" &
                      "statsoffset = " & $result.statsOffset & "\n" &
                      "nocolor = false\n" &
                      "customlogo = \"\"  # full path to a PNG logo\n"
        writeFile(path, content)
    except IOError:
      discard
  else:
    try:
      let logoDir = homeCfg / "logos"
      if not dirExists(logoDir): createDir(logoDir)
      if dirExists(logoDir): result.configLogoDir = logoDir
    except IOError:
      discard
