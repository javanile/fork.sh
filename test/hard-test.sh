#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh 1 2 3

cd test/repos/forkfile-test3
echo fakemessage > HARD
bash ../../../fork.sh --hard
test diff HARD ../forkfile-test1/HARD
