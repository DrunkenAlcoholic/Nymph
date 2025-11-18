import std/[os, terminal, math, strutils, strformat, dirs, random, sets, base64, posix]


const
  DefaultLogoName = "generic"
  sourceLogoDir = parentDir(currentSourcePath()) / "logos"
  projectLogoDir = parentDir(parentDir(currentSourcePath())) / "logos"
  LogoPixelSize = 200
  kittyChunkSize = 4096
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
    flamingo:  "\x1b[38;2;242;205;205m",
    pink:      "\x1b[38;2;245;194;231m",
    mauve:     "\x1b[38;2;203;166;247m",
    red:       "\x1b[38;2;243;139;168m",
    maroon:    "\x1b[38;2;235;160;172m",
    peach:     "\x1b[38;2;250;179;135m",
    yellow:    "\x1b[38;2;249;226;175m",
    green:     "\x1b[38;2;166;227;161m",
    teal:      "\x1b[38;2;148;226;213m",
    sky:       "\x1b[38;2;137;220;235m",
    sapphire:  "\x1b[38;2;116;199;236m",
    blue:      "\x1b[38;2;137;180;250m",
    lavender:  "\x1b[38;2;180;190;254m",
    bold:      "\x1b[1m",
    rbold:     "\x1b[22m",
    itali:     "\x1b[3m",
    ritali:    "\x1b[23m",
    reset:     "\x1b[0m",
  )


proc normalizeDir(path: string): string =
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

  if isAbsolute(expanded):
    expanded
  else:
    absolutePath(expanded)


proc getLogoSearchDirs(): seq[string] =
  var dirs = @[sourceLogoDir, projectLogoDir]
  let envDir = getEnv("NYMPH_LOGO_DIR")
  if envDir.len > 0: dirs.add envDir
  let appDir = getAppDir()
  if appDir.len > 0:
    dirs.add appDir / "logos"
    dirs.add appDir / "../share/nymph/logos"

  var seen = initHashSet[string]()
  for dir in dirs:
    let norm = normalizeDir(dir)
    if norm.len > 0 and not seen.contains(norm):
      seen.incl(norm)
      result.add norm


proc locateLogoFile(name, ext: string): string =
  let fileName = name.toLowerAscii() & ext
  for dir in getLogoSearchDirs():
    let path = dir / fileName
    if fileExists(path): return path
  ""


proc loadLogo(name: string): string =
  let path = locateLogoFile(name, ".png")
  if path.len == 0: return ""
  try:
    readFile(path)
  except IOError:
    ""


when defined(posix):
  type
    TermWinSize = object
      ws_row: cushort
      ws_col: cushort
      ws_xpixel: cushort
      ws_ypixel: cushort

  const ioctlWinSize = culong(0x5413)


proc getWindowPixels(): tuple[width, height: int] =
  when defined(posix):
    var ws: TermWinSize
    if ioctl(STDOUT_FILENO, ioctlWinSize, addr ws) == 0:
      return (int(ws.ws_xpixel), int(ws.ws_ypixel))
  (0, 0)


proc getCellMetrics(): tuple[cellWidth, cellHeight: float] =
  let cols = terminalWidth()
  let rows = terminalHeight()
  let winPixels = getWindowPixels()
  var cellWidth = 8.0
  var cellHeight = 16.0
  if winPixels.width > 0 and cols > 0:
    cellWidth = winPixels.width.float / cols.float
  if winPixels.height > 0 and rows > 0:
    cellHeight = winPixels.height.float / rows.float
  (cellWidth, cellHeight)


proc supportsKittyGraphics(): bool {.inline.} =
  let term = getEnv("TERM").toLowerAscii()
  if term.contains("kitty"): return true
  if getEnv("KITTY_WINDOW_ID").len > 0: return true
  if getEnv("TERM_PROGRAM").toLowerAscii() == "kitty": return true
  false


proc displayKittyImage(logoBytes: string; columns, rows: int) =
  if logoBytes.len == 0: return
  let encoded = encode(logoBytes)
  var offset = 0
  var firstChunk = true
  while offset < encoded.len:
    let chunkEnd = min(offset + kittyChunkSize, encoded.len)
    let chunk = encoded[offset ..< chunkEnd]
    var controlParts: seq[string] = @[]
    if firstChunk:
      controlParts.add("a=T")
      controlParts.add("f=100")
      controlParts.add("t=d")
      controlParts.add("q=2")
      controlParts.add("C=1")
      if columns > 0: controlParts.add("c=" & $columns)
      if rows > 0: controlParts.add("r=" & $rows)
    if chunkEnd < encoded.len:
      controlParts.add("m=1")
    stdout.write("\x1b_G")
    if controlParts.len > 0:
      stdout.write(controlParts.join(","))
    if chunk.len > 0:
      stdout.write(";")
      stdout.write(chunk)
    stdout.write("\x1b\\")
    offset = chunkEnd
    firstChunk = false


proc collectAvailableLogos(): seq[string] =
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
  for ch in name.toLowerAscii():
    if ch.isAlphaNumeric:
      result.add(ch)


proc findBestLogoMatch(candidates: seq[string]): string =
  var available = collectAvailableLogos()
  if available.len == 0:
    return ""

  let availSet = block:
    var tmp = initHashSet[string]()
    for name in available:
      tmp.incl(name)
    tmp

  proc tryMatch(value: string): string =
    let sanitized = sanitizeLogoName(value)
    if sanitized.len == 0:
      return ""
    if sanitized in availSet:
      return sanitized
    for avail in available:
      if avail.contains(sanitized) or sanitized.contains(avail):
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


proc parseLogoOverride(): string =
  let params = commandLineParams()
  var i = 0
  while i < params.len:
    let param = params[i]
    if param.startsWith("--logo=") or param.startsWith("-logo="):
      return param.split('=', 1)[1]
    elif param == "--logo" or param == "-logo":
      if i + 1 < params.len:
        return params[i + 1]
    inc i
  ""


proc detectLogoName(): string =
  var candidates: seq[string] = @[]

  let cliLogo = parseLogoOverride()
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
  var distroname = ""
  if fileExists(osReleasePath):
    for line in lines(osReleasePath):
      if line.startsWith("PRETTY_NAME="):
        return line.split('=', 1)[1].strip(chars = {'"', '\''})
      elif line.startsWith("NAME="):
        distroname = line.split('=', 1)[1].strip(chars = {'"', '\''})

  if distroname != "":
    return distroname

  return "Unknown Linux Distribution"


proc getKernel(): string {.inline.} =
  if fileExists(versionFile):
    let tokens = readFile(versionFile).splitWhitespace()
    if tokens.len >= 3:
      return tokens[2]
    elif tokens.len > 0:
      return tokens[^1]
  "Unknown Kernel Version"


proc getPackages(): int {.inline.} =
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
  let randIcon = icons[rand(icons.high)]
  fmt"{col.rosewater}{randIcon} {col.mauve}{randIcon} {col.pink}{randIcon} {col.maroon}{randIcon} {col.sky}{randIcon} {col.green}{randIcon} {col.lavender}{randIcon} "

const
  outputFormat = [
    (22, 1, fmt"{col.rosewater}{icon.os}  {col.yellow}{col.bold}OS:{col.reset}      $#"),
    (22, 2, fmt"{col.pink}{icon.kernel}  {col.yellow}{col.bold}Kernel:{col.reset}  $#"),
    (22, 3, fmt"{col.mauve}{icon.desktop}  {col.yellow}{col.bold}DE/WM:{col.reset}   $#"),
    (22, 4, fmt"{col.maroon}{icon.pkgs}  {col.yellow}{col.bold}Pkgs:{col.reset}    $#"),
    (22, 5, fmt"{col.sky}{icon.shell}  {col.yellow}{col.bold}Shell:{col.reset}   $#"),
    (22, 6, fmt"{col.green}{icon.uptime}  {col.yellow}{col.bold}Uptime:{col.reset}  $#"),
    (22, 7, fmt"{col.lavender}{icon.memory}  {col.yellow}{col.bold}Memory:{col.reset}  $#"),
    (30, 8, fmt"$#{col.reset}")
  ]


proc computeLogoCells(): tuple[cols, rows: int] =
  let metrics = getCellMetrics()
  let cw = max(1.0, metrics.cellWidth)
  let ch = max(1.0, metrics.cellHeight)
  let cols = max(1, int(ceil(LogoPixelSize.float / cw)))
  let rows = max(1, int(ceil(LogoPixelSize.float / ch)))
  (cols, rows)


when isMainModule:
  randomize()
  stdout.eraseScreen()

  let kittyCapable = supportsKittyGraphics()
  let detectedLogoName = detectLogoName()
  var logo = loadLogo(detectedLogoName)
  if logo.len == 0:
    logo = loadLogo(DefaultLogoName)

  let values = [
    getOS(),
    getKernel(),
    getDE(),
    $getPackages(),
    getShell(),
    getUptime(),
    getMemory(),
    getColours()
  ]

  if kittyCapable and logo.len > 0:
    stdout.setCursorPos(1, 1)
    let placement = computeLogoCells()
    displayKittyImage(logo, placement.cols, placement.rows)
  else:
    stdout.setCursorPos(1, 1)
    stdout.write(AsciiFallbackLogo)

  for i, (y, x, format) in outputFormat.pairs:
    stdout.setCursorPos(y, x)
    stdout.write(format % values[i])
  stdout.write("\n\n")
  stdout.flushFile()
