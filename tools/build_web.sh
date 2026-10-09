#!/usr/bin/env bash
# Builds the browser version with love.js into a static folder that can be
# served by any web server, e.g. GitHub Pages.
#
# Usage: tools/build_web.sh [output_dir]    (default: build/web)
# Needs: node/npx, zip.

set -euo pipefail

# Fork of love.js whose LÖVE build uses WebGL 2 (array textures); installed from its GitHub tag
# (not the npm registry). npm 12+ refuses git packages unless --allow-git permits it.
LOVEJS_PACKAGE="github:cptobakhmut925-glitch/love.js#v11.4.1-webgl2.1"
# Initial WebAssembly heap; it grows on demand, but love.js needs a big enough start.
MEMORY_BYTES=$((128 * 1024 * 1024))

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(realpath -m "${1:-$root/build/web}")"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

cd "$root"
zip -9 -r -q "$staging/game.love" main.lua conf.lua src assets

rm -rf "$out"
# -c: the compatibility build runs without SharedArrayBuffer, which needs
# COOP/COEP response headers that GitHub Pages cannot send.
npx --yes --allow-git=root "$LOVEJS_PACKAGE" -c -t "love-mcraft" -m "$MEMORY_BYTES" "$staging/game.love" "$out"
sed "s/{{memory}}/$MEMORY_BYTES/" "$root/tools/web/index.html" > "$out/index.html"
rm -rf "$out/theme" # styles for the stock page replaced above
cp "$root/tools/web/favicon.png" "$root/tools/web/apple-touch-icon.png" "$out/"
touch "$out/.nojekyll"

echo "Built $out — test locally with: python3 -m http.server -d '$out'"
