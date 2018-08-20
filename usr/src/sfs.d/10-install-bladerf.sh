#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "$build_dir"
save_prebuild_state

test -d "$bladerf_src" || git clone "$(dl_file "$bladerf_url")" "$bladerf_src"

apt-get install -y $deb_build_bladerf

cd "$bladerf_src"
dpkg-buildpackage ${build_procs:+-j$build_procs} -us -uc -b

deb_source_add_dir "$build_dir"

"$lbu/scripts/apt-sfs.sh" "$DESTDIR" bladerf

test -z "$BLADERF_HOST" || {
  apt-get -y install --allow-unauthenticated "bladerf-fpga-hostedx$(echo "$BLADERF_HOST" | tr A-Z a-z)"
  cp --parents -avt "$DESTDIR" /usr/share/Nuand/bladeRF
}
