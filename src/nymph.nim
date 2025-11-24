import std/[os, terminal, math, strutils, strformat, random, sets, posix]
import kitty_proto, nymph_settings

type
  # Holds raw PNG bytes and dimensions so we can size the Kitty placement.
  LogoData = object
    bytes: string
    width: int
    height: int

const
  DefaultLogoName = "generic"
  sourceLogoDir = parentDir(currentSourcePath()) / "logos"
  projectLogoDir = parentDir(parentDir(currentSourcePath())) / "logos"
  AsciiFallbackLogo = """  
      .---.   
      /     \    
      \.@-@./    
      /`\_/`\    
     //  _  \\    
    | \     )|_   
   /`\_`>  <_/ \_  
   \__/''---''\__/ 

""" & "\n"

  icons = static: [" ", " ", " ", " ", "󰯉 ", " ", " ", "󰞦 ", "󰄊 ", "󱖿 ", " ", "󰌽 ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "󰢚 ", "󰆚 ", "󰩃 ", "󱔐 ", "󱕘 ", "󱜿 ", "󰻀 ", "󰳆 ", "󱗂 "]

  osReleasePath = "/etc/os-release"
  versionFile =   "/proc/version"
  uptimeFile =    "/proc/uptime"
  meminfoPath =   "/proc/meminfo"
  secsPerDay =    24 * 60 * 60
  gibDivisor =    1024.0 * 1024.0
  mibDivisor =    1024

  icon = (
    os:      " ", 
    kernel:  " ", 
    pkgs:    "󰏖 ", 
    desktop: "󰇄 ", 
    shell:   " ", 
    uptime:  " ", 
    memory:  "󰍛 "
    )

  col = (
    rosewater: "\x1b[38;2;245;224;220m",
    pink:      "\x1b[38;2;245;194;231m",
    mauve:     "\x1b[38;2;203;166;247m",
    maroon:    "\x1b[38;2;235;160;172m",
    yellow:    "\x1b[38;2;249;226;175m",
    green:     "\x1b[38;2;166;227;161m",
    sky:       "\x1b[38;2;137;220;235m",
    lavender:  "\x1b[38;2;180;190;254m",
    bold:      "\x1b[1m",
    reset:     "\x1b[0m",
  )

var appConfig: RuntimeConfig = defaultConfig()
var disableColor = false
var metricsCached = false
var cachedMetrics: tuple[cellWidth, cellHeight: float]


proc getLogoSearchDirs(): seq[string] =
  ## Assemble all directories we search for logos (env/app/source/project).
  let envDir = getEnv("NYMPH_LOGO_DIR")
  let appDir = getAppDir()
  var seen = initHashSet[string]()

  for dir in [sourceLogoDir, projectLogoDir]:
    let norm = normalizeDir(dir)
    if norm.len > 0 and not seen.contains(norm):
      seen.incl(norm)
      result.add norm

  if appConfig.configLogoDir.len > 0:
    let norm = normalizeDir(appConfig.configLogoDir)
    if norm.len > 0 and not seen.contains(norm):
      seen.incl(norm)
      result.add norm

  if envDir.len > 0:
    let norm = normalizeDir(envDir)
    if norm.len > 0 and not seen.contains(norm):
      seen.incl(norm)
      result.add norm

  if appDir.len > 0:
    let dir = normalizeDir(appDir / "logos")
    if dir.len > 0 and not seen.contains(dir):
      seen.incl(dir)
      result.add dir


proc locateLogoFile(name, ext: string): string =
  ## Return the first logo file that matches the provided name/extension.
  let fileName = name.toLowerAscii() & ext
  for dir in getLogoSearchDirs():
    let path = dir / fileName
    if fileExists(path): return path
  ""


proc parsePngDims(data: string): (int, int) =
  ## Read the PNG IHDR chunk to extract width/height.
  if data.len < 24: return (0, 0)
  if not data.startsWith("\x89PNG\x0d\x0a\x1a\x0a"): return (0, 0)
  let w = (ord(data[16]) shl 24) or (ord(data[17]) shl 16) or (ord(data[18]) shl 8) or ord(data[19])
  let h = (ord(data[20]) shl 24) or (ord(data[21]) shl 16) or (ord(data[22]) shl 8) or ord(data[23])
  (w, h)


proc loadLogo(name: string): LogoData =
  ## Load PNG bytes and dimensions for the given logo name.
  let path = locateLogoFile(name, ".png")
  if path.len == 0: return
  try:
    let raw = readFile(path)
    if raw.len == 0: return
    let (w, h) = parsePngDims(raw)
    if w <= 0 or h <= 0: return
    result.bytes = raw
    result.width = w
    result.height = h
  except IOError:
    discard


proc loadLogoFromPath(path: string): LogoData =
  ## Load a PNG from an explicit path.
  let norm = normalizeDir(path)
  if norm.len == 0 or not fileExists(norm): return
  try:
    let raw = readFile(norm)
    if raw.len == 0: return
    let (w, h) = parsePngDims(raw)
    if w <= 0 or h <= 0: return
    result.bytes = raw
    result.width = w
    result.height = h
  except IOError:
    discard


when defined(posix):
  type
    TermWinSize = object
      ws_row: cushort
      ws_col: cushort
      ws_xpixel: cushort
      ws_ypixel: cushort

  const ioctlWinSize = culong(0x5413)

proc getWindowPixels(): tuple[width, height: int] =
  ## Query the terminal window size in pixels (falls back to 0s).
  when defined(posix):
    var ws: TermWinSize
    if ioctl(STDOUT_FILENO, ioctlWinSize, addr ws) == 0:
      return (int(ws.ws_xpixel), int(ws.ws_ypixel))
  (0, 0)


proc getCellMetrics(): tuple[cellWidth, cellHeight: float] =
  ## Derive approximate cell width/height in pixels from window metrics (cached).
  if metricsCached:
    return cachedMetrics

  let cols = terminalWidth()
  let rows = terminalHeight()
  let winPixels = getWindowPixels()
  var cellWidth = 8.0
  var cellHeight = 16.0
  if winPixels.width > 0 and cols > 0:
    cellWidth = winPixels.width.float / cols.float
  if winPixels.height > 0 and rows > 0:
    cellHeight = winPixels.height.float / rows.float

  cachedMetrics = (cellWidth: cellWidth, cellHeight: cellHeight)
  metricsCached = true
  cachedMetrics

proc collectAvailableLogos(): seq[string] =
  ## Enumerate unique logo names detected across all search paths.
  var seen = initHashSet[string]()
  for dir in getLogoSearchDirs():
    try:
      for kind, path in walkDir(dir):
        if kind != pcFile: continue
        let ext = path.splitFile.ext.toLowerAscii()
        if ext == ".png":
          let name = path.splitFile.name.toLowerAscii()
          if not seen.contains(name):
            seen.incl(name)
            result.add name
    except OSError:
      discard


proc sanitizeLogoName(name: string): string =
  ## Strip non-alphanumeric characters before matching names.
  for ch in name.toLowerAscii():
    if ch.isAlphaNumeric:
      result.add(ch)


proc findBestLogoMatch(candidates: seq[string]): string =
  ## Pick the first candidate that matches an available logo.
  let available = collectAvailableLogos()
  if available.len == 0:
    return ""

  proc tryMatch(value: string): string =
    let sanitized = sanitizeLogoName(value)
    if sanitized.len == 0:
      return ""
    for avail in available:
      if avail == sanitized or avail.contains(sanitized) or sanitized.contains(avail):
        return avail
    ""

  for cand in candidates:
    let matched = tryMatch(cand)
    if matched.len > 0:
      return matched

  let genericMatch = tryMatch("generic")
  if genericMatch.len > 0:
    return genericMatch

  let defaultMatch = tryMatch(DefaultLogoName)
  if defaultMatch.len > 0:
    return defaultMatch

  available[0]


proc parseCliOptions(): tuple[logo: string, noColor: bool] =
  ## Parse minimal CLI flags: logo override and --no-color toggle.
  let params = commandLineParams()
  var i = 0
  while i < params.len:
    let param = params[i]
    if param.startsWith("--logo=") or param.startsWith("-logo="):
      result.logo = param.split('=', 1)[1]
    elif param == "--logo" or param == "-logo":
      if i + 1 < params.len:
        result.logo = params[i + 1]
    elif param == "--no-color" or param == "--no-colors":
      result.noColor = true
    inc i


proc detectLogoName(cliLogo: string): string =
  ## Build a list of candidate names from CLI, env vars, and os-release.
  var candidates: seq[string] = @[]

  if cliLogo.len > 0:
    candidates.add cliLogo

  let envLogo = getEnv("NYMPH_LOGO")
  if envLogo.len > 0:
    candidates.add envLogo

  if fileExists(osReleasePath):
    var idValue = ""
    var idLikeValues: seq[string] = @[]
    var pretty = ""
    var nameValue = ""
    for line in lines(osReleasePath):
      if line.startsWith("ID="):
        idValue = line.split('=', 1)[1].strip(chars = {'"', '\''})
      elif line.startsWith("ID_LIKE="):
        let values = line.split('=', 1)[1].strip(chars = {'"', '\''}).splitWhitespace()
        for v in values:
          idLikeValues.add v
      elif line.startsWith("PRETTY_NAME="):
        pretty = line.split('=', 1)[1].strip(chars = {'"', '\''})
      elif line.startsWith("NAME="):
        nameValue = line.split('=', 1)[1].strip(chars = {'"', '\''})

    if idValue.len > 0: candidates.add idValue
    for v in idLikeValues: candidates.add v
    if nameValue.len > 0: candidates.add nameValue
    if pretty.len > 0: candidates.add pretty

  candidates.add DefaultLogoName

  findBestLogoMatch(candidates)


proc getOS(): string {.inline.} =
  ## Return PRETTY_NAME from /etc/os-release or fall back to NAME.
  var distroname = ""
  if fileExists(osReleasePath):
    for line in lines(osReleasePath):
      if line.startsWith("PRETTY_NAME="):
        return line.split('=', 1)[1].strip(chars = {'"', '\''})
      elif line.startsWith("NAME="):
        distroname = line.split('=', 1)[1].strip(chars = {'"', '\''})

  if distroname.len == 0:
    return "Unknown Linux Distribution"
  distroname


proc getKernel(): string {.inline.} =
  ## Read kernel version from /proc/version (fallback to last token).
  if fileExists(versionFile):
    let tokens = readFile(versionFile).splitWhitespace()
    if tokens.len >= 3:
      return tokens[2]
    elif tokens.len > 0:
      return tokens[^1]
  "Unknown Kernel Version"


proc getPackages(): int {.inline.} =
  ## Naive package-count heuristic: checks common package manager dirs.
  let packageDirs = [
    "/var/lib/pacman/local",       # Pacman (Arch, Manjaro)
    "/var/lib/eopkg/package",      # Eopkg (Solus)
    "/var/lib/flatpak/app",        # Flatpak
    "/var/db/pkg",                 # Portage (Gentoo)
    "/var/db/xbps",                # XBPS (Void Linux)
    "/usr/local/opt",              # Homebrew (macOS)
    "/var/lib/portage/world",      # Portage (Gentoo alternative location)
    "/var/lib/apk/db",             # APK (Alpine Linux)
    "/var/lib/guix"                # Guix System
  ]
  
  for dir in packageDirs:
    if dirExists(dir):
      var count = 0
      for kind, path in walkDir(dir):
        if kind == pcDir: 
          count.inc
      
      if count > 0:
        result = count
        return result
  
  let aptStatusFile = "/var/lib/dpkg/status"
  if fileExists(aptStatusFile):
    var seenPkg = false
    for line in lines(aptStatusFile):
      if line.startsWith("Package:"):
        seenPkg = true
      elif line.startsWith("Status:") and seenPkg:
        if "install ok installed" in line:
          result.inc
        seenPkg = false
      elif line.len == 0:
        seenPkg = false
    return result
  
  return 0


proc getShell(): string {.inline.} =
  ## Resolve the current shell from SHELL/$USER’s /etc/passwd entry.
  let shellEnv = getEnv("SHELL")
  if shellEnv.len > 0:
    let basename = shellEnv.splitPath().tail
    if basename.len > 0:
      return basename

  let userName = getEnv("USER")
  try:
    for line in lines("/etc/passwd"):
      let parts = line.split(':')
      if parts.len >= 7 and parts[0] == userName:
        let shellPath = parts[6]
        if shellPath.len > 0:
          return shellPath.splitPath().tail
  except IOError:
    discard

  "Unknown"


proc getUptime(): string =
  ## Format /proc/uptime into “X days, HH:MM:SS”.
  var uptime: float
  try:
    uptime = parseFloat(readFile(uptimeFile).split()[0])
  except IOError, ValueError:
    return "Unable to read uptime"

  let
    uptimeDays = int(uptime / secsPerDay)
    uptimeSeconds = int(uptime.mod(secsPerDay))
    hours = uptimeSeconds div 3600
    minutes = (uptimeSeconds mod 3600) div 60
    seconds = uptimeSeconds mod 60

  fmt"{uptimeDays} days, {hours:02d}:{minutes:02d}:{seconds:02d}"


proc getMemory(): string =
  ## Compute used memory using the htop formula (total - free/buffers/cached).
  var 
    memTotal, memFree, buffers, cached, shmem, sreclaimable: int
  
  if fileExists(meminfoPath):
    for line in lines(meminfoPath):
      let parts = line.split(":")
      if parts.len != 2: continue
      
      case parts[0].strip()
      of "MemTotal": memTotal = parts[1].strip().split()[0].parseInt()
      of "MemFree": memFree = parts[1].strip().split()[0].parseInt()
      of "Buffers": buffers = parts[1].strip().split()[0].parseInt()
      of "Cached": cached = parts[1].strip().split()[0].parseInt()
      of "Shmem": shmem = parts[1].strip().split()[0].parseInt()
      of "SReclaimable": sreclaimable = parts[1].strip().split()[0].parseInt()
  
  let usedMem = memTotal - (memFree + buffers + cached) + (shmem - sreclaimable)
  
  if usedMem >= 1048576:
    return fmt"{usedMem.float / gibDivisor:0.2f}GiB / {memTotal.float / gibDivisor:0.2f}GiB"
  else:
    return fmt"{usedMem div mibDivisor}MiB / {memTotal div mibDivisor}MiB"

  
proc getDE(): string =
  ## Try common desktop environment variables, fallback to WM name.
  result = getEnv("XDG_CURRENT_DESKTOP")
  if result == "":
    result = getEnv("DESKTOP_SESSION")
  if result == "":
    result = getEnv("GDMSESSION")
  if result == "":
    let wmName = getEnv("WINDOW_MANAGER")
    if wmName != "":
      result = wmName.splitPath().tail
  if result == "":
    result = "Unknown"
    

proc getColours(): string {.inline.} =
  ## Print a sequence of colored icons to mimic fetch “color blocks”.
  let randIcon = icons[rand(icons.high)]
  fmt"{col.rosewater}{randIcon} {col.mauve}{randIcon} {col.pink}{randIcon} {col.maroon}{randIcon} {col.sky}{randIcon} {col.green}{randIcon} {col.lavender}{randIcon} "

type StatEntry = object
  ## Describes where to print each stat line and how to obtain its value.
  col: int
  row: int
  formatter: string
  getter: proc(): string {.closure.}

proc statsEntries(statsCol: int): seq[StatEntry] =
  ## Build the ordered list of stats rows with their value suppliers.
  result = @[
    StatEntry(col: statsCol, row: 1, formatter: fmt"{col.rosewater}{icon.os}  {col.yellow}{col.bold}OS:{col.reset}      $#", getter: proc(): string = getOS()),
    StatEntry(col: statsCol, row: 2, formatter: fmt"{col.pink}{icon.kernel}  {col.yellow}{col.bold}Kernel:{col.reset}  $#", getter: proc(): string = getKernel()),
    StatEntry(col: statsCol, row: 3, formatter: fmt"{col.mauve}{icon.desktop}  {col.yellow}{col.bold}DE/WM:{col.reset}   $#", getter: proc(): string = getDE()),
    StatEntry(col: statsCol, row: 4, formatter: fmt"{col.maroon}{icon.pkgs}  {col.yellow}{col.bold}Pkgs:{col.reset}    $#", getter: proc(): string = $getPackages()),
    StatEntry(col: statsCol, row: 5, formatter: fmt"{col.sky}{icon.shell}  {col.yellow}{col.bold}Shell:{col.reset}   $#", getter: proc(): string = getShell()),
    StatEntry(col: statsCol, row: 6, formatter: fmt"{col.green}{icon.uptime}  {col.yellow}{col.bold}Uptime:{col.reset}  $#", getter: proc(): string = getUptime()),
    StatEntry(col: statsCol, row: 7, formatter: fmt"{col.lavender}{icon.memory}  {col.yellow}{col.bold}Memory:{col.reset}  $#", getter: proc(): string = getMemory()),
    StatEntry(col: statsCol, row: 8, formatter: fmt"       $#{col.reset}", getter: proc(): string = getColours())
  ]


proc computeLogoCells(logo: LogoData): tuple[cols, rows: int] =
  ## Convert PNG dimensions to terminal cell counts while preserving aspect ratio.
  let metrics = getCellMetrics()
  let cw = max(1.0, metrics.cellWidth)
  let ch = max(1.0, metrics.cellHeight)
  let targetWidth = min(logo.width, appConfig.maxLogoWidth)
  let scale = targetWidth.float / max(logo.width.float, 1.0)
  let targetHeight = logo.height.float * scale
  var cols = max(1, int(ceil(targetWidth.float / cw)))
  var rows = max(1, int(ceil(targetHeight / ch)))
  # Keep the logo from consuming the entire viewport; if too wide, scale down.
  let maxCols = max(1, terminalWidth())
  let maxRows = max(1, terminalHeight())
  let halfCols = max(1, maxCols div 2) # limit to half the screen width
  if cols > halfCols:
    let scaleDown = halfCols.float / cols.float
    cols = halfCols
    rows = max(1, int(ceil(rows.float * scaleDown)))
  elif cols >= maxCols:
    cols = maxCols - 1
  if rows >= maxRows:
    rows = maxRows - 1
  (cols, rows)


proc computeStatsOffset(): int =
  ## Derive a stats start column based on logo width and cell metrics.
  let metrics = getCellMetrics()
  let cw = max(1.0, metrics.cellWidth)
  let colsFromLogo = int(ceil(appConfig.maxLogoWidth.float / cw)) + 2 # padding
  let base = max(appConfig.statsOffset, colsFromLogo)
  let maxCols = max(1, terminalWidth())
  min(base, maxCols div 2 + 2)


proc stripAnsi(text: string): string =
  ## Remove ANSI escape sequences for --no-color output.
  var i = 0
  while i < text.len:
    if text[i] == '\x1b' and i + 1 < text.len and text[i + 1] == '[':
      var j = i + 2
      while j < text.len and text[j] notin {'m', '\\'}:
        inc j
      if j < text.len:
        i = j + 1
        continue
    result.add(text[i])
    inc i


when isMainModule:
  randomize()
  stdout.eraseScreen()

  appConfig = loadConfig()
  let cli = parseCliOptions()
  if cli.noColor or appConfig.noColor:
    disableColor = true
  let logoOverride = cli.logo

  # Resolve logo name and load PNG bytes/dimensions if possible.
  var logo: LogoData
  let overridePath = normalizeDir(logoOverride)
  if overridePath.len > 0 and fileExists(overridePath):
    logo = loadLogoFromPath(overridePath)
  elif appConfig.customLogoFile.len > 0:
    logo = loadLogoFromPath(appConfig.customLogoFile)
  let kittyCapable = supportsKittyGraphics()
  let detectedLogoName = detectLogoName(if overridePath.len == 0: logoOverride else: "")
  if logo.bytes.len == 0:
    logo = loadLogo(detectedLogoName)
  if logo.bytes.len == 0:
    logo = loadLogo(DefaultLogoName)

  if kittyCapable and logo.bytes.len > 0:
    stdout.setCursorPos(1, 1)
    let placement = computeLogoCells(logo)
    displayKittyGraphics(logo.bytes, placement.cols, placement.rows)
  else:
    stdout.setCursorPos(1, 1)
    stdout.write(AsciiFallbackLogo)

  let statsCol = computeStatsOffset()
  # Render stats block next to the logo.
  for entry in statsEntries(statsCol):
    stdout.setCursorPos(entry.col, entry.row)
    let line = entry.formatter % entry.getter()
    stdout.write(if disableColor: stripAnsi(line) else: line)
  stdout.write("\n\n")
  stdout.flushFile()
