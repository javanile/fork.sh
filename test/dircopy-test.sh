#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh 1 2 3

cd test/repos/forkfile-test3
rm -fr data/data_files files/
bash ../../../fork.sh
#bash ../../../fork.sh --hard

test find \
    files/FILE1.txt \
    files/FILE2.txt \
    data/data_files/FILE1.txt \
    data/data_files/FILE2.txt
