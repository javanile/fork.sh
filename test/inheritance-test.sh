#!/usr/bin/env bash
set -e

git config --global credential.helper 'cache --timeout=3000'

[[ ! -d test/repos ]] && mkdir -p test/repos
cd test/repos

[[ ! -d forkfile-test1 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test1.git
cd forkfile-test1
date > RELEASE
git add .
git commit -am "Forkfile"
git push
cd ..

[[ ! -d forkfile-test2 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test2.git
cd forkfile-test2
date > RELEASE
git add .
git commit -am "Forkfile"
git push
cd ..

[[ ! -d forkfile-test3 ]] && git clone https://gitlab.com/javanile/fixtures/forkfile-test3.git
cd forkfile-test3
date > RELEASE
echo ""
echo ""
echo "====[ FORK.SH ]===="
../../../fork.sh
cd ..
