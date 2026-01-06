#!/bin/sh

run_lint() {
  echo "Running ShellCheck..."
  shellcheck -s sh qvm drivers/*.sh
}

run_test() {
  echo "Running Bats tests..."
  bats tests/
}

usage() {
  echo "Usage: $0 [lint|test]"
  echo "If no argument is provided, runs both lint and test."
  exit 1
}

if [ $# -eq 0 ]; then
  EXIT_CODE=0

  run_lint || EXIT_CODE=1
  run_test || EXIT_CODE=1

  exit $EXIT_CODE
fi

CMD="$1"

case "$CMD" in
  lint)
    run_lint
    ;;
  test)
    run_test
    ;;
  *)
    usage
    ;;
esac
