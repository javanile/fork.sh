#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh

cd test/repos/forkfile-test3
echo "new test" > HARD
../../../fork.sh --hard

echo ""
echo "====[ TESTING ]===="
diff HARD ../forkfile-test1/HARD
