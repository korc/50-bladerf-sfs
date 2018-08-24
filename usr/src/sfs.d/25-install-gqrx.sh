#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "$build_dir"

test -e "$gqrx_src/CMakeLists.txt" || {
: "${gqrx_txz:=$(dl_file "$gqrx_url")}"
  mkdir -p "$gqrx_src"
  tar xfJ "$gqrx_txz" -C "$gqrx_src" --strip-components=1
}

apt-get install -y $deb_build_gqrx

( cd "$grosmosdr_src/build" && make install/strip DESTDIR="" )

mkdir -p "$gqrx_src/build"
cd "$gqrx_src/build"

cmake ..
make ${build_procs:+-j$build_procs}
make install/strip DESTDIR="$DESTDIR"
