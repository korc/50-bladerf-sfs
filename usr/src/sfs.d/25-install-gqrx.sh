#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "$build_dir"

test -d "$gqrx_src" || git clone "$(dl_file "$gqrx_url")" "$gqrx_src"

apt-get install -y $deb_build_gqrx

( cd "$grosmosdr_src/build" && make install/strip DESTDIR="" )

mkdir -p "$gqrx_src/build"
cd "$gqrx_src/build"

apply_patches "$gqrx_src" "gqrx"
cmake ..
make ${build_procs:+-j$build_procs}
make install/strip DESTDIR="$DESTDIR"
