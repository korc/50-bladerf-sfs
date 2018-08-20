#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "$build_dir"

test -d "$grosmosdr_src" || git clone "$(dl_file "$grosmosdr_url")" "$grosmosdr_src"

apt-get install -y --allow-unauthenticated $deb_build_grosmosdr

mkdir -p "$grosmosdr_src/build"
cd "$grosmosdr_src/build"

cmake ..
make ${build_procs:+-j$build_procs}
make install/strip DESTDIR="$DESTDIR"
