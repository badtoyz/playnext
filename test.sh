#!/bin/bash

playnext=$(dirname $(readlink -f $0))/playnext

function fail() {
  echo "FAIL: $@"
  echo "Last command: $last_command"
  echo "Backtrace:"
  i=0
  while caller $(( i++ )); do true; done
  exit 1
}

function playnext() {
  args="-f $progress_file"
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
  ! playnext "$@" > /dev/null 2>&1 || fail "$message"
}

function set_up_fixture() {
  media_dir_1=$(mktemp -d)
  cd $media_dir_1
  mkdir "Dir 1"
  touch "Dir 1/File 1"
  touch "Dir 1/file 2"
  touch "Dir 1/File 3"
  mkdir "Dir 2"
  mkdir "Dir 3"
  touch "Dir 3/File 1"
  touch ".dotfile"
  mkdir ".dotdir"
  touch ".dotdir/file"

  media_dir_2=$(mktemp -d)
  cd $media_dir_2
  mkdir "Dir 4"
  touch "Dir 4/File 1"
  touch "File 2"

  media_dir_3=$(mktemp -d)

  progress_file=$(mktemp)
}

function tear_down_fixture() {
  rm -r "$media_dir_1" "$media_dir_2" "$media_dir_3"
}

function set_up() {
  cd ${TMPDIR-/tmp}
}

function tear_down() {
  rm -f $progress_file
}

function test_with_empty_dir() {
  cd $media_dir_3
  assert_fail "Did not fail with empty dir"
}

function test_with_some_files() {
  cd $media_dir_1
  assert_output "$media_dir_1/Dir 1/File 1"
  assert_output "$media_dir_1/Dir 1/file 2"
  assert_output "$media_dir_1/Dir 1/File 3"
  assert_output "$media_dir_1/Dir 3/File 1"
  assert_fail "Did not run out of files"
}

function test_multiple_episodes_in_progress() {
  cd $media_dir_1
  playnext "Dir 1" -e "Dir 1/File 1" > /dev/null
  playnext "Dir 3" -e "Dir 3/File 1" > /dev/null
  assert_fail "Did not warn about multiple episodes in progress"
}

function test_multiple_media_dirs() {
  cd $media_dir_1
  playnext > /dev/null
  cd $media_dir_2
  playnext > /dev/null
  assert_output "$(echo -e "$media_dir_1/Dir 1/File 1\n$media_dir_2/Dir 4/File 1")" -l
}

function test_directory_argument() {
  assert_output "$media_dir_1/Dir 1/File 1" $media_dir_1
  assert_fail "Did not fail with multiple directories" $media_dir_1 $media_dir_2
}

function test_episode_option() {
  cd $media_dir_1
  assert_output "$media_dir_1/Dir 1/file 2" -e "Dir 1/file 2"
  assert_output "$media_dir_1/Dir 1/File 3"
  assert_fail "Invalid file for -e was accepted" -e /dev/null
}

function test_help_option() {
  playnext -h | grep -q "Usage" || fail "Did not print usage"
}

function test_list_option() {
  playnext $media_dir_1 > /dev/null
  playnext $media_dir_2 > /dev/null
  file=$(cat $progress_file)
  assert_output "$file" -l
}

function test_no_advance_option() {
  cd $media_dir_1
  assert_output "$media_dir_1/Dir 1/File 1"
  assert_output "$media_dir_1/Dir 1/file 2" -n
  assert_output "$media_dir_1/Dir 1/file 2" -n
}

function test_previous_option() {
  cd $media_dir_1
  assert_output "$media_dir_1/Dir 1/File 1"
  assert_output "$media_dir_1/Dir 1/File 1" -p
  assert_output "$media_dir_1/Dir 1/File 1" -p
}

function test_command_option() {
  cd $media_dir_1
  assert_output "" -c cat
  assert_output "$media_dir_1/Dir 1/file 2" -c echo
}

set_up_fixture
trap tear_down_fixture EXIT
while read function; do
  [[ ! $function = test* ]] && continue
  set_up
  $function
  tear_down
  echo "PASS: $function"
done < <(declare -F | cut -d' ' -f3)
