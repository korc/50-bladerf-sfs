#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

fix_missing_dest_libs "$DESTDIR"
