#!/bin/sh

: "${lbu:=/opt/LiveBootUtils}"
. "$lbu/scripts/common.func"

: "${git_repo_base:=https://github.com/Nuand}"
: "${bladerf_url:=$git_repo_base/bladeRF.git}"
: "${grosmosdr_url:=$git_repo_base/gr-osmosdr.git}"
: "${gqrx_url:=$git_repo_base/gqrx.git}"

: "${build_dir:=/usr/src/deb}"
: "${bladerf_src:=$build_dir/bladerf}"
: "${grosmosdr_src:=$build_dir/gr-osmosdr}"
: "${gqrx_src:=$build_dir/gqrx}"
: "${_prebuild_liblist:=$build_dir/prebuild-libs.list}"
: "${dpkg_statusfile:=$(find_apt_fullpath Dir::State::status)}"
: "${_prebuild_dpkg_status:=$build_dir/prebuild-dpkg_status}"

: "${deb_build_bladerf:=cmake doxygen libusb-1.0-0-dev libtecla-dev help2man pandoc}"
: "${deb_build_grosmosdr:=libbladerf-dev gnuradio-dev swig gr-iqbal}"
: "${deb_build_gqrx:=qtbase5-dev libpulse-dev libqt5svg5-dev}"

: "${_apt_sources_dir:=$(find_apt_fullpath Dir::Etc::sourceparts)}"
: "${_apt_list_dir:=$(find_apt_fullpath Dir::State::lists)}"

: "${build_procs:=$(grep -c ^processor /proc/cpuinfo)}"

save_prebuild_state() {
  ldconfig -p | grep -o '=> .*' | cut -f2 -d" " | sort -u >"$_prebuild_liblist"
  cp "$dpkg_statusfile" "$_prebuild_dpkg_status"
}

fix_missing_dest_libs() {
  local dest="${1:-$DESTDIR}" pkg lib pkg_list
  ldconfig
  for lib in $(find "$dest" \( -newer "$_prebuild_liblist" -o -cnewer "$_prebuild_liblist" \) -type f -exec file {} + | grep ELF | cut -f1 -d: | xargs ldd | grep -o '=> .*' | cut -f2 -d" " | sort -u | grep -vFx -f "$_prebuild_liblist" -);do
    test ! -e "${dest}$lib" -a ! -L "${dest}$lib" || continue
    if pkg="$(dpkg -S "$lib")";then
      pkg="${pkg%%:*}"
      grep -e "^Package: $pkg$" -e "^Status: " "$_prebuild_dpkg_status" | grep -A1 "^Package: " | grep "^Status: " | grep -qw installed || {
        case " $pkg_list " in
          *" $pkg "*) ;;
          *) pkg_list="${pkg_list:+$pkg_list }$pkg";;
        esac
      }
    else
      cp --parents -avt "$dest" "$lib"
    fi
  done
  test -z "$pkg_list" || dpkg_status="$_prebuild_dpkg_status" "$lbu/scripts/apt-sfs.sh" "$dest" $pkg_list
}

deb_source_add_dir() {
  local dir="$(readlink -f "$1")" safe_name list_file pkg_cache_file
  test -d "$dir" || {
    echo "Usage: deb_source_add_dir <dirname>" >&2
    return 1
  }
  safe_name="$(echo "$dir" | tr / _)"
  test "$dir/Packages" -nt "$dir" || (cd "$dir"; dpkg-scanpackages . > Packages)
  list_file="$_apt_sources_dir/$safe_name.list"
  test -e "$list_file" || echo "deb file://$dir ./" >"$list_file"
  pkg_cache_file="$_apt_list_dir/${safe_name}_._Packages"
  test "$pkg_cache_file" -nt "$dir/Packages" || cp "$dir/Packages" "$pkg_cache_file"
}

apply_patches() {
  local dir="$1" name="${2:-$(basename "$1")}" patch wd="${wd:-$(dirname "$0")}"
  for patch in $(find "$wd/.patches" -name "${name}_[0-9][0-9]-*.patch" | sort);do
    (cd "$dir"; patch -p1 < "$patch")
  done
}
