#!/bin/bash

playnext=$(dirname $(readlink -f $0))/playnext
media_dir=$(mktemp -d)
progress_file=$(mktemp)

args="-f $progress_file"
if [[ $1 == "-v" ]]; then
  args="$args -v"
fi

function fail() {
  echo "FAIL: $@"
  echo "Last command: $last_command"
  echo "Backtrace:"
  i=0
  while caller $(( i++ )); do true; done
  exit 1
}

function playnext() {
  last_command="$playnext $args $@"
  $playnext $args "$@"
}

function assert_output() {
  local expected="$1"
  shift
  local actual="$(playnext "$@")"
  if (( $? )); then
    fail "Nonzero exit code"
    exit 1
  fi
  if [[ $expected != $actual ]]; then
    fail "Expected: $expected, actual: $actual"
    exit 1
  fi
}

function assert_fail() {
  message="$1"
  shift
  last_command="$@"
  ! playnext "$@" 2>/dev/null || fail "$message"
}

function reset_progress() {
  rm $progress_file
}

cd $media_dir

# Some files that should be ignored
touch ".dotfile"
mkdir ".dotdir"
touch ".dotdir/file"

# Test with empty dir
assert_fail "Did not fail with empty dir"

# Test with some files
mkdir "Dir 1"
touch "Dir 1/File 1"
touch "Dir 1/file 2"
touch "Dir 1/File 3"
mkdir "Dir 2"
mkdir "Dir 3"
touch "Dir 3/File 1"

assert_output "$media_dir/Dir 1/File 1"
assert_output "$media_dir/Dir 1/file 2"
assert_output "$media_dir/Dir 1/File 3"
assert_output "$media_dir/Dir 3/File 1"
assert_fail "Did not run out of files"

# Test multiple episodes in progress
reset_progress
playnext -d "Dir 1" -e "Dir 1/File 1" > /dev/null
playnext -d "Dir 3" -e "Dir 3/File 1" > /dev/null
assert_fail "Did not warn about multiple episodes in progress"

# Test -d
reset_progress
pushd /tmp > /dev/null
assert_output "$media_dir/Dir 1/File 1" -d $media_dir
popd > /dev/null

# Test -e
assert_output "$media_dir/Dir 1/file 2" -e "Dir 1/file 2"
assert_output "$media_dir/Dir 1/File 3"
assert_fail "Invalid file for -e was accepted" -e /dev/null

# Test -h
playnext -h | grep -q "Usage" || fail "Did not print usage"

# Test -l
reset_progress
file=$(playnext)
assert_output "$file" -l

# Test -n
reset_progress
assert_output "$media_dir/Dir 1/File 1"
assert_output "$media_dir/Dir 1/file 2" -n
assert_output "$media_dir/Dir 1/file 2" -n

# Test -p
reset_progress
assert_output "$media_dir/Dir 1/File 1"
assert_output "$media_dir/Dir 1/File 1" -p
assert_output "$media_dir/Dir 1/File 1" -p

rm -r "$media_dir"
rm -r "$progress_file"

echo "PASS"
