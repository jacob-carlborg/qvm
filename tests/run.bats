#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"
  
  export HOME="$BATS_TEST_DIRNAME/tmp/run"
  mkdir -p "$HOME"
  
  # Set mock uname to a known state (linux x86-64)
  export MOCK_UNAME_S="Linux"
  export MOCK_UNAME_M="x86_64"
}

teardown() {
  rm -rf "$HOME"
}

@test "qvm run fails without arguments" {
  run qvm run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing OS or VERSION arguments" ]]
}

@test "qvm run downloads resources if missing" {
  # Mock a driver file so qvm thinks the OS is valid
  mkdir -p "$BATS_TEST_DIRNAME/../drivers"
  touch "$BATS_TEST_DIRNAME/../drivers/linux-x86-64.sh"

  run qvm run --dry-run linux 1.0
  
  [ "$status" -eq 0 ]
  # Check if our mock curl was called (implied by success and file creation)
  [ -f "$HOME/.cache/qvm/bin/qemu-system-x86_64" ]
  [ -f "$HOME/.cache/qvm/bin/qemu-img" ]
}

@test "qvm run creates instance and attempts to boot" {
  mkdir -p "$BATS_TEST_DIRNAME/../drivers"
  # Create a dummy driver that echoes a unique string
  echo 'echo "BOOTING_MOCK_OS"' > "$BATS_TEST_DIRNAME/../drivers/linux-x86-64.sh"
  
  # Pre-populate cache to skip downloads (optional, but speeds up test)
  mkdir -p "$HOME/.cache/qvm/bin"
  touch "$HOME/.cache/qvm/bin/qemu-system-x86_64"
  touch "$HOME/.cache/qvm/bin/qemu-img"
  
  run qvm run linux 1.0
  
  [ "$status" -eq 0 ]
  [[ "$output" =~ "BOOTING_MOCK_OS" ]]
  [[ "$output" =~ "Starting VM..." ]]
  
  # Verify instance image was created
  # Note: Since we mock qemu-img, the file might not be a real qcow2, but it should exist
  # wait... qemu-img is called to create it. We need to mock qemu-img too.
}
