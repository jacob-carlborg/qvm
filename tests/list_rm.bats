#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/..:$PATH"
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"
  
  # Set a temp cache dir for isolation
  # Use a temp directory within the project tests directory
  export HOME="$BATS_TEST_DIRNAME/tmp/list_rm"
  mkdir -p "$HOME/.cache/qvm/instances"
}

teardown() {
  rm -rf "$HOME"
}

@test "qvm list shows no instances when empty" {
  # The setup function creates the directory, which prevents the "No VM instances found" 
  # message from triggering (since the code checks if the directory exists).
  # We remove it to test this specific code path.
  rmdir "$HOME/.cache/qvm/instances"
  
  run qvm list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No VM instances found" ]]
}

@test "qvm list shows created instances" {
  # Mock instance files
  touch "$HOME/.cache/qvm/instances/test-vm-1.qcow2"
  touch "$HOME/.cache/qvm/instances/test-vm-2.qcow2"
  
  run qvm list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Created VM Instances:" ]]
  [[ "$output" =~ "test-vm-1" ]]
  [[ "$output" =~ "test-vm-2" ]]
}

@test "qvm rm removes an instance" {
  touch "$HOME/.cache/qvm/instances/to-delete.qcow2"
  
  run qvm rm to-delete
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Removed VM instance: to-delete" ]]
  
  [ ! -f "$HOME/.cache/qvm/instances/to-delete.qcow2" ]
}

@test "qvm rm warns if instance not found" {
  run qvm rm non-existent
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Warning: VM instance not found: non-existent" ]]
}

@test "qvm rm handles multiple arguments" {
  touch "$HOME/.cache/qvm/instances/vm1.qcow2"
  touch "$HOME/.cache/qvm/instances/vm2.qcow2"
  
  run qvm rm vm1 vm2
  [ "$status" -eq 0 ]
  
  [[ "$output" =~ "Removed VM instance: vm1" ]]
  [[ "$output" =~ "Removed VM instance: vm2" ]]
  
  [ ! -f "$HOME/.cache/qvm/instances/vm1.qcow2" ]
  [ ! -f "$HOME/.cache/qvm/instances/vm2.qcow2" ]
}
