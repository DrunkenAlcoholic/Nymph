import std/[os, terminal, math, strutils, strformat]


const
  CachyOS =       static: r"_Ga=T,f=100,m=1;iVBORw0KGgoAAAANSUhEUgAAAOAAAACxCAYAAADd/7GzAAA8TElEQVR4Ae2dCZhcVZn3f+dutfWadNJZWRMQERFERAYdcT4HB2UARxF1VBCVwQVxH2fGb+Is6izquIyCK24jNioiyufCEBRFwACGELZEQvalu9NrbXc553uee+7tvl3pTnqp7q7q1O/Jear63Ftb6v7rPed93/MewUJBKZH4SyOESvzVoEHNcehFW290dTmw/TxMsTLRq1FKAW6iZ2KU8EEFiZ6JUaqc+GtCLNP2EchE1/goQ/kBXqJnYmzhIuWRf1gMIQncST2nkxKukFbVfqxS2EH6MM83QJlyW/Nuzr+ylOg+Kql7Adr//rUzfbP320qlVtOhIFsCoUCJ6NOJIwtAo8J/k0FNQlQABnKyTwmTeU41hc8TWv/J/aBM5kdCv7yazLlCCTX+6EMFFIoZlU4/gW2/hUvf83Ti4FFJfQuwqytj7Mz/o7T73oOlHPoXQVsArYNgRz/+9f0Ja4twQDFFFCAVeJ7+LkzLw3E+TvaZH+PCCyc1kljIGIn7dYeV6jhTiuxrwXZoDcD0YLAZ9nZAbxu4dmTUGlPBqiDE5BuAlOB64HtgmZBywHGeSNnW/zTEp6lbAXZu3Jjz050fQjmrECY4EtrLYApQWRhqg71LYaAZpBmJsCHEOUFK8Hwtvlh4tgVC+EjxyfJD/VsSZx/V1KcAu5S5/0D2NezPX4SVMkIBAjQVwSqA6YCVBpGFg4tgdycMpbUQGxqcPUKL50PJ0/dTjhZgaBGVBPP2Vbzge6xbN8l57MKnPgW4fPeJlI23Y9ngpMBydL+loG0IjACcNNhpsDMQ5KC3Ew4shmJ6dFjaEGN1iIeaJTcSng3pFBjR5RXOHY1dlml+Ztdl5xYTjzzqqT8BbthgG2bqNdipU3GcSIDRxxBAtgDZARCGPuakdTOzUGqBA53QvRTcVOQobKhw2igFvg/FSHhpR1s9s/KyEgHCvs3PLb4v0dmgHgWYsk46XpF9LWYqTSpDKEKRGj3BUNA0CJarj6UiAYYtA0Yaiq2wpxP62sC3Rx/bYHKEwgv0UNP1tcVLJSxe5bmGsQ9hfpsL3phPHGlQbwJcsWFD1pfZ9yjDWjsiLDut53wj3k4BVhHsg2AIbQVTqeg2eozlgMhA/2LYv0Q7avyGo+aIxMIrR8IzBWRS0TwvOqcy7COEbxjG59jNQ4neBhF1JcCe1GkvC5T5JizLwo6Gn6EFjK1Y9O0LINOnk2AsB+xU1KLHjNymIWiFvg7YvxSKWR3Ab4jwUKTSwiu7+octbYNjj4YcxiOc+5n3Llq65gtce20j7DAOdSPAzL2FVa5nvh1FJpzfWXYkrrT2eFZiFcDaqed5Tho9XE1rKxjfD0Vog5kGvwn2dkLPYihlGkKMCYXnQjHSTyalhTfecLMSYRx0jMxnes67eCjR2yBBfQiwq8ss29bLkcbZY4Y4hgmmpUUUHkgKRoDTA6pHizUpvFQa0pnRIenIcDYDhcVwYKm2im48tzwKPaZKRZ7Nko4gpG3tZJmM8PTjJcL8petYdyV6G1RQFwLMnfKnHUpYbwXRnOgeFZyK4oCVGB5Yu0C5ox7RpOjSGUjHVjE+lgIjB4OtcGA5DLaANKL80sRzL1SU0kH0fDFysDj6/8ic4P94PJQCYQxjmF/lFW/rTRxpUEHtC3CDsstq0duVEqdPK69T9EOwX/9yJz2iYYww8oymImsY3maiviyoHPQtg70rYahJC3GhqjAOKZRdbfkcB3JTFN4o0hDG19ec9vJfz+uSMKVE58Z9OX6z+RjWP/EMfrnpFH776LFh33jL1+aBmheglS6e7fvW1SisRPckESB8EDtBlvScMSm4UIixgyZy6DjRL/6IRUzrQH5fJ/QuhWJuVIgLQYuxxSu52uIZpp7n6dSxxImTRIcdHnFM87+2rl07b46XFytlWXc+fH73UPnjBJnvYaZ+iNP0Q4JMV/dA8T+tuzb9GevWTeOaqi41LcCWewYWBeX0e5B0Tmj9RjL0D/dRDoK3R98dEVckwnAuGFu9aI4YOnds3eKhq5mBcrselnZ3LoxAvpSRg6WkxZZOgWPpJIZp2wdRsK3cDaV5XGq05vYtqV//Ztu7fdvqktJ9O8I/B7xTEN4zwD9bIt/mG8038eJL37Nmi0oEkeee2hXgunVGPpV+MfCiRO/4HHE04UPwJHjD+hd+xOLFQ9IoRpgcko4MVRPBfNvRHlO3TQtxoB3cOAZZRwRR6lixrL2cuWzkYEmEcaaHwjDu8Zzgx4m+uWX9+vTWZvedkuF/RcjFiJKJKIMoEd6G657LBqK4GMP49627N72De+7JJJ5hTqlZAbZd/O4WKcyrFGLxEa1fmGR9mKtGCFB9UH4CgmA0Q2YkQJ8MUSTmifGcMOmkScWB/BwMdELPMhhoHV1xUatiVCqRs1nSAfWUrYebh6SOTYPwuxAlTPPLDC/bmzgyp9gdHc/CKb0V00uF2VDJZnpglkebEYDpv92SqbMSTzGn1KwAi2bur5Uy/2xS73EyjgIB+H+EQnRthPO9hPVLDktDYVbEDGMxptO6OVG/aoGBpbB3FRSbRsMhtSZEP4BCEdzII5xNgzXNed54hD9y4herzjrnNi67bHIr8WcBLy9fieWdRNoD2x9tlq8XaSeb44LjHytN+fJJDKNmhZoUoLOx/CzXt9+LoorjcwEqD8XHoDSsBWJaYzNjnDhrJpobhn3R3yPnJMIYIyGNLKgm6F4B3cuhnNbf53yLMHSwBFAoaeHZth5u2mZi7lwlhLFjaab5H3etnsfVDl1dDhnvHFJK4ChIy9GWkpBSet3o2GZJixeg5kcLNSfAzo0q5wfO1Upy/JTmIpP5ARNAsAsGd4IbOejCOaGdmBPGuaMJoSWD9iOxxEi4yaGpkwWvDXpXwcGl4CUC+XOJUnqoXXK1k8UyI+eTM2rxqmX59OuVDOF87cBFf/NwonfOaVl1ahNpbyVZRdjSiZaJBJmpaGkJLeWORffdl0s81ZxRcwLsxX++gksTXZNkkheUKED5D1Ac1hdp/FjTjDJmYidMInl7ZAiaCF3EQ1A74TENj2fAaILiIuheqQP6gTV3w1IptfDyRZ3Bko1Sx6oxzxsPpcA0N8sg+M58u4RNpxiwuNWn2SBsTWJsy0W32URrEpAShuG3zct7ry0BbtyXU764UkmWTdkTF6+KnwzqAOSfBK88digmhA7YWxUWMZzzxR7SVGQRI+fNSAgjPSrEeKGwyMLgSjiwEoZbZzeQHztYQs+mhGxGt8mmjk0XIVywvkFfbnuid17oGxrKkytvI2cSthYLmqL7TaYWZS4SZ3w/Z0BbanuPt3dehs41JUDHaP/zAPMVCKaWfhF6ICeL0JX9vMch3w3STxyLTxHaQTFm9UQkxtjyjUlry+jhZ9JSjlhLB2SL9ph2L4N8c0KIVRBjnLNZKOmAumNrB8tsWbxKhPXbnNXUxdVXT66u6Wzy4hcHKOMOUsIjbRC2rDnaQiEao63FgJzpYtv3cv7541wIs8+08oxmAZHbNNxZ9tI3osQxk7Z+vgflEpQKwC6d+zmpBwudHypz4HRokYw3J4orfJmWHqIahm6hpTR1wDruM4S2wuF9M0oUTxwXFsgU5HN6tUW6pN3g8fuZDqFnMwopZFI6kG5G76+ac7wJMQYyTttbChe/9bFE5/whhMHZJ/dgGX+KKZfr/4fovzdsQn9PySbEU/jiX/jY9fsSzzRn1IYF3LLFKfuZNyslTk30zi7CB38L5HvBO0zx7PhiHm9oGjtjRixiHL7IjM4TQydOhbWUrbB/NQwkVlxM1hgqojIQZd1sA5qy2mLPJUr5GOI7xb+86p5E7/yybp1ky3OeNntaPkdg7D38f6oCKboJnH/jsdMfSRyYU2rCAtpXfuKMAPv/osTSKRkDz9UWsFzQ+Z6TtoBEVrCkh4NWp7aCh5svJYU4YtWMyOJELbR8sTVMWseKFp5vQzmrc0sVYHlgxMXCJvgMgYRyWS+MtYwodewIi2JnA73a4UmE/Y888wW7E0fmny99VKr//MAT5pDaqgx/DYIORMVyGSV8fHOD\_Gm=1;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\_Gm=1;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\_Gm=1;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\_Gm=1;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\_Gm=0;5aBWg9OWXAA8QNp7K+et/P7R5HhJsmCuUPum/3qe1+N9F9s8kUVeIs2/wfwThS2CjI4dshSsNmhr/m7rMuMdA88+9qgdriycK7SrK2ME+/5OmqU3IGT9Fr5c6CgTglZB89o+21Zv8i54yQOJo0cd/x+PNdIPjYLXKQAAAABJRU5ErkJggg==\"
  osReleasePath = static: "/etc/os-release"
  versionFile =   static: "/proc/version"
  packageDir =    static: "/var/lib/pacman/local"
  uptimeFile =    static: "/proc/uptime"
  meminfoPath =   static: "/proc/meminfo"
  secsPerDay =    static: 24 * 60 * 60
  gibDivisor =    static: 1024.0 * 1024.0
  mibDivisor =    static:1024

  icon = (
    os:      " ", 
    kernel:  " ", 
    pkgs:    "󰏖 ", 
    desktop: "󰇄,", 
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
    reset:     "\x1b[0m"
  )

proc getOS(): string {.inline.} =
  if fileExists(osReleasePath):
    for line in lines(osReleasePath):
      if line.startsWith("PRETTY_NAME="):
        return line.split('=', 1)[1].strip(chars = {'"', '\''})
  "Unknown Linux Distribution"

proc getKernel(): string {.inline.} =
  if fileExists(versionFile):
    readFile(versionFile).splitWhitespace()[2]
  else:
    "Unknown Kernel Version"

proc getPackages(): int {.inline.} =
  for kind, path in walkDir(packageDir):
    if kind == pcDir: result.inc

proc getShell(): string {.inline.} =
  getEnv("SHELL").splitPath().tail

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

proc getMemInfo(key: string): int {.inline.} =
  for line in lines(meminfoPath):
    let parts = line.split(":")
    if parts.len == 2 and parts[0].strip() == key:
      return parts[1].strip().split()[0].parseInt()
  

proc getMemory(): string =
  let
    iMemTotal =     getMemInfo("MemTotal")
    iMemFree =      getMemInfo("MemFree")
    iBuffers =      getMemInfo("Buffers")
    iCached =       getMemInfo("Cached")
    iShmem =        getMemInfo("Shmem")
    iSReclaimable = getMemInfo("SReclaimable")
    iUsedMem = iMemTotal - (iMemFree + iBuffers + iCached) + (iShmem - iSReclaimable)

  if iUsedMem >= 1048576:
    fmt"{iUsedMem.float / gibDivisor:0.2f}GiB / {iMemTotal.float / gibDivisor:0.2f}GiB"
  else:
    fmt"{iUsedMem div mibDivisor}MiB / {iMemTotal div mibDivisor}MiB"

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
  fmt"{col.rosewater}◉ {col.mauve}◉ {col.pink}◉ {col.maroon}◉ {col.sky}◉ {col.green}◉ {col.lavender}◉"


when isMainModule:
  stdout.erasescreen()

  stdout.setcursorpos(1,1)
  write(stdout, CachyOS)

  const outputFormat = [
    (24, 1, fmt"{col.rosewater}{icon.os}  {col.yellow}{col.bold}OS:{col.reset}      $#"),
    (24, 2, fmt"{col.mauve}{icon.desktop}  {col.yellow}{col.bold}DE/WM:{col.reset}   $#"),
    (24, 3, fmt"{col.pink}{icon.kernel}  {col.yellow}{col.bold}Kernel:{col.reset}  $#"),
    (24, 4, fmt"{col.maroon}{icon.pkgs}  {col.yellow}{col.bold}Pkgs:{col.reset}    $#"),
    (24, 5, fmt"{col.sky}{icon.shell}  {col.yellow}{col.bold}Shell:{col.reset}   $#"),
    (24, 6, fmt"{col.green}{icon.uptime}  {col.yellow}{col.bold}Uptime:{col.reset}  $#"),
    (24, 7, fmt"{col.lavender}{icon.memory}  {col.yellow}{col.bold}Memory:{col.reset}  $#"),
    (34, 9, fmt"$#{col.reset}")
  ]

  let values = [
    getOS(),
    getDE(),
    getKernel(),
    $getPackages(),
    getShell(),
    getUptime(),
    getMemory(),
    getColours()
  ]

  for i, (y, x, format) in outputFormat.pairs:
    stdout.setCursorPos(y, x)
    stdout.write(format % values[i])

  stdout.flushFile()
