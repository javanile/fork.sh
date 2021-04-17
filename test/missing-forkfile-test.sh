#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh 4

cd test/repos/forkfile-test4
../../../fork.sh && true
../../../fork.sh --from javanile/forkfile && true
rm -f Forkfile


