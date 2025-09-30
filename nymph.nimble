version       = "0.5.0"
author        = "Nymph Contributors"
description   = "Lightweight system summary with kitty graphics logos"
license       = "MIT"
srcDir        = "src"
bin           = @["nymph"]
binDir        = "bin"

requires "nim >= 1.6.0"

# Build tasks
task release, "Build the application with release flags":
  exec "nim c -d:release -d:danger --passL:'-s' --opt:size -o:./bin/nymph src/nymph.nim"
