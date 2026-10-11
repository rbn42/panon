#!/bin/sh
# Install the translations to ~/.local/share/locale, to test them without packaging.
cd "$(dirname "$0")"
cmake -B build -DCMAKE_INSTALL_PREFIX="$HOME/.local/share/locale"
cmake --build build --target install
