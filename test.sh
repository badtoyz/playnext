#!/bin/bash

playnext=$(dirname $(readlink -f $0))/playnext

function fail() {
  echo "$@"
  echo "Backtrace:"
  i=0
  while caller $(( i++ )); do true; done
  exit 1
}

function playnext() {
  (
    echo "Running command:"
    echo -n "$playnext -f $progress_file -v"
    for arg in "$@"; do
      if [[ $arg =~ "^[a-zA-Z0-9]*$" ]]; then
        echo -n " $arg"
      else
        echo -n " '$arg'"
      fi
    done
    echo
  ) >&2
  $playnext -f $progress_file "$@"
}

function assert_output() {
  local expected="$1"
  shift
  local actual="$(playnext "$@")"
  if (( $? )); then
    fail "Nonzero exit code"
  fi
  if [[ $expected != $actual ]]; then
    fail "Expected: $expected"$'\n'"Actual: $actual"
  fi
}

function assert_fail() {
  message="$1"
  shift
  ! playnext "$@" > /dev/null 2>&1 || fail "$message"
}

function set_up_fixture() {
  cd "$(dirname $0)/testdata"
  media_dir_1=$(readlink -f t1)
  media_dir_2=$(readlink -f t2)
  media_dir_3=$(readlink -f t3)
}

function tear_down_fixture() {
  true
}

function set_up() {
  progress_file=$(mktemp)
}

function tear_down() {
  rm -f $progress_file
}

function test_with_empty_dir() {
  assert_fail "Did not fail with empty dir" $media_dir_3
}

function test_with_some_files() {
  assert_output "$media_dir_1/Dir 1/File 1" $media_dir_1
  assert_output "$media_dir_1/Dir 1/file 2" $media_dir_1
  assert_output "$media_dir_1/Dir 1/File 3" $media_dir_1
  assert_output "$media_dir_1/Dir 3/File 1" $media_dir_1
  assert_fail "Did not run out of files"
}

function test_multiple_episodes_in_progress() {
  playnext "$media_dir_1/Dir 1" -e "Dir 1/File 1" > /dev/null
  playnext "$media_dir_1/Dir 3" -e "Dir 3/File 1" > /dev/null
  assert_fail "Did not warn about multiple episodes in progress"
}

function test_multiple_media_dirs() {
  playnext $media_dir_1 > /dev/null
  playnext $media_dir_2 > /dev/null
  assert_output "$(echo -e "$media_dir_1/Dir 1/File 1\n$media_dir_2/Dir 4/File 1")" -l
}

function test_directory_argument() {
  assert_output "$media_dir_1/Dir 1/File 1" $media_dir_1
  assert_fail "Did not fail without directory argument"
  assert_fail "Did not fail with multiple directories" $media_dir_1 $media_dir_2
}

function test_directory_substring() {
  playnext $media_dir_1 > /dev/null
  playnext $media_dir_2 > /dev/null
  assert_output "$media_dir_1/Dir 1/file 2" "r 1"
  assert_fail "Did not complain about multiple substring matches" 1
}

function test_filename_argument() {
  cd $media_dir_1
  assert_output "$media_dir_1/Dir 1/file 2" "Dir 1/file 2"
  assert_output "$media_dir_1/Dir 1/File 3" $media_dir_1
}

function test_episode_option() {
  assert_output "$media_dir_1/Dir 1/file 2" $media_dir_1 -e "Dir 1/file 2"
  assert_output "$media_dir_1/Dir 1/File 3" $media_dir_1
  assert_fail "Invalid file for -e was accepted" $media_dir_1 -e /dev/null
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

function test_next_option() {
  assert_output "$media_dir_1/Dir 1/file 2" $media_dir_1 -n
  assert_output "$media_dir_1/Dir 3/File 1" $media_dir_1 -n
}

function test_previous_option() {
  playnext $media_dir_1 > /dev/null
  assert_output "$media_dir_1/Dir 1/File 1" $media_dir_1 -p
  assert_output "$media_dir_1/Dir 1/file 2" $media_dir_1
  assert_output "$media_dir_1/Dir 1/File 1" $media_dir_1 -p -p
}

function test_command_option() {
  assert_output "" $media_dir_1 -c cat
  assert_output "$media_dir_1/Dir 1/file 2" $media_dir_1 -c echo
}

pass_count=0
fail_count=0
set_up_fixture
trap tear_down_fixture EXIT
while read function; do
  [[ ! $function = test* ]] && continue
  set_up
  output=$($function 2>&1)
  if (( $? )); then
    echo "FAIL: $function"
    echo "$output"
    (( fail_count++ ))
  else
    echo "PASS: $function"
    (( pass_count++ ))
  fi
  tear_down
done < <(declare -F | cut -d' ' -f3)
echo "$pass_count passes, $fail_count failures"
