#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh

cd test/repos/forkfile-test3
echo fakemessage > HARD
bash ../../../fork.sh --hard
test diff HARD ../forkfile-test1/HARD
