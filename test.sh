#!/usr/bin/env bash

set -euo pipefail

cd `dirname "$0"`
exec nvim --headless --clean -c "set runtimepath+=`pwd` | luafile test.lua"
