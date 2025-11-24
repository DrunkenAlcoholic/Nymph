import std/[os, strutils, base64]

const kittyChunkSize = 4096

proc supportsKittyGraphics*(): bool =
  ## Detect whether we’re inside a terminal that speaks Kitty graphics.
  const candidates = ["kitty", "wezterm", "ghostty", "konsole"]
  let termVars = [getEnv("TERM"), getEnv("TERM_PROGRAM"), getEnv("TERMINAL_EMULATOR")]
  for v in termVars:
    let low = v.toLowerAscii()
    for name in candidates:
      if low.contains(name): return true
  if getEnv("KITTY_WINDOW_ID").len > 0: return true
  if getEnv("WEZTERM_VERSION").len > 0 or getEnv("WEZTERM_EXECUTABLE").len > 0: return true
  if getEnv("GHOSTTY_RESOURCES_DIR").len > 0: return true
  if getEnv("KONSOLE_VERSION").len > 0 or getEnv("KONSOLE_DBUS_SESSION").len > 0: return true
  false


proc displayKittyGraphics*(logoBytes: string; columns, rows: int) =
  ## Stream the PNG bytes via Kitty’s graphics protocol.
  if logoBytes.len == 0: return
  let encoded = encode(logoBytes)
  var offset = 0
  var first = true
  while offset < encoded.len:
    let chunkEnd = min(offset + kittyChunkSize, encoded.len)
    let chunk = encoded[offset ..< chunkEnd]
    var ctrl: seq[string] = @[]
    if first:
      ctrl.add("a=T")
      ctrl.add("f=100")
      ctrl.add("t=d")
      ctrl.add("q=2")
      ctrl.add("C=1")
      if columns > 0: ctrl.add("c=" & $columns)
      if rows > 0: ctrl.add("r=" & $rows)
    ctrl.add("m=" & (if chunkEnd < encoded.len: "1" else: "0"))
    stdout.write("\x1b_G")
    if ctrl.len > 0: stdout.write(ctrl.join(","))
    if chunk.len > 0:
      stdout.write(";")
      stdout.write(chunk)
    stdout.write("\x1b\\")
    offset = chunkEnd
    first = false
