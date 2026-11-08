#!/bin/sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
editor=${1:-vim}
case $(basename "$editor") in
  nvim*) flags=--headless ;;
  *) flags=--not-a-term ;;
esac
failures=0

run_case() {
  if DAYBREAK_TEST_CASE=$1 DAYBREAK_TEST_HOUR=$2 DAYBREAK_TEST_SCHEME=${3:-} \
    "$editor" -N -u NONE -i NONE $flags -S "$root/tests/regression.vim" </dev/null; then
    :
  else
    failures=$((failures + 1))
  fi
}

for hour in 0 5 6 18 19 23; do
  run_case clock "$hour"
done
run_case explicit_setup 19
run_case macos 12
run_case windows_dark 12
run_case windows_light 12
run_case windows_console 19

if [ "$(uname -s)" = Linux ]; then
  run_case linux_headless 12
  run_case linux_desktop 12
  run_case gdbus_read 12 0
  run_case gdbus_read 12 1
  run_case gdbus_read 12 2
fi

case $(basename "$editor") in
  nvim*)
    "$editor" --headless -u NONE -i NONE -l "$root/tests/lazy.lua" || failures=$((failures + 1))
    ;;
  *)
    run_case automatic_setup 19
    ;;
esac

if [ "$failures" -ne 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
echo "PASS all cases with $editor"
