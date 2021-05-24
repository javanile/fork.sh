#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh 1 2 3

cd test/repos/forkfile-test3
rm -fr INHERITANCE.txt
bash ../../../fork.sh
test find INHERITANCE.txt
