#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  # Prepend mocks directory to PATH
  export PATH="$MOCKS_DIR:$PATH"
  
  # Isolate tests from the real filesystem
  # Use a temp directory within the project tests directory
  export HOME="$BATS_TEST_DIRNAME/tmp/config"
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$HOME"
}

@test "qvm config print-path prints the cache directory" {
  run qvm config print-path
  [ "$status" -eq 0 ]
  # The script hardcodes CACHE_DIR="${HOME}/.cache/qvm"
  # We should expect that specific path structure
  [[ "$output" == "$HOME/.cache/qvm" ]]
}

@test "qvm config --help prints usage" {
  run qvm config --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage: qvm config" ]]
}

@test "qvm config invalid-command fails" {
  run qvm config invalid-command
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown config command" ]]
}
