#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"
  
  export HOME="$BATS_TEST_DIRNAME/tmp/pull"
  mkdir -p "$HOME"
  
  # Set mock uname to a known state (linux x86-64)
  export MOCK_UNAME_S="Linux"
  export MOCK_UNAME_M="x86_64"
}

teardown() {
  rm -rf "$HOME"
}

@test "qvm pull fails without arguments" {
  run qvm pull
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing OS or VERSION arguments" ]]
}

@test "qvm pull downloads base image" {
  run qvm pull linux 1.0
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Image cached successfully" ]]
  
  # Check if the file exists in the expected path
  # linux-1.0-x86-64.qcow2 (based on default mock uname)
  [ -f "$HOME/.cache/qvm/base_images/linux-1.0-x86-64.qcow2" ]
}

@test "qvm pull supports --platform flag" {
  run qvm pull --platform arm64 linux 1.0
  [ "$status" -eq 0 ]
  
  # Check for arm64 specific file
  [ -f "$HOME/.cache/qvm/base_images/linux-1.0-arm64.qcow2" ]
}
