#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh

cd test/repos/forkfile-test3
../../../fork.sh --hard
test diff -Z PROTOTYPE.md PROTOTYPE.expected.md
