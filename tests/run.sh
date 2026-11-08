#!/bin/sh
# Runs the plugin tests against a mocked PrusaSlicer API with every available Lua
# interpreter, for both possible origins of api.make_cylinder (base or center).
set -e
cd "$(dirname "$0")/.."
PLUGIN="$PWD/io.github.molekuly3d.molecules"
ran=0
for lua in lua5.4 luajit; do
    command -v "$lua" >/dev/null || continue
    ran=1
    for mode in base center; do
        out=$("$lua" tests/test_plugin.lua "$PLUGIN" "$mode" tests/fixtures/carbon_dioxide.sdf 2>&1)
        echo "$out" | grep -E '^(FAIL|OK|[0-9]+ failures)' | sed "s/^/$lua: /"
        echo "$out" | grep -q '^OK' || exit 1
    done
    out=$("$lua" tests/test_v3000.lua "$PLUGIN" tests/fixtures/acacetin_v3000.sdf 2>&1)
    echo "$lua: v3000 $out"
    [ "$out" = "OK" ] || exit 1
    out=$("$lua" tests/test_v2000_paste.lua "$PLUGIN" tests/fixtures/adenosine.sdf 2>&1)
    echo "$lua: v2000 paste $out"
    [ "$out" = "OK" ] || exit 1
done
[ "$ran" = 1 ] || { echo "No Lua interpreter (lua5.4 or luajit) found"; exit 1; }
