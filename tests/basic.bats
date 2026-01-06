#!/usr/bin/env bats

setup() {
  # Add the project root to PATH so we can run `qvm`
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
  
  # Isolate tests from the real filesystem
  # Use a temp directory within the project tests directory
  export HOME="$BATS_TEST_DIRNAME/tmp/basic"
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$HOME"
}

@test "qvm --help prints usage information" {
  run qvm --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage: qvm" ]]
}

@test "qvm --version prints version" {
  run qvm --version
  [ "$status" -eq 0 ]
}
