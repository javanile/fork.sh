#!/usr/bin/env bash
set -e

git config --global credential.helper 'cache --timeout=3000'

[[ ! -d test/fixtures ]] && mkdir -p test/fixtures
cd test/fixtures

[[ ! -d forkfile ]] && git clone https://github.com/javanile/forkfile
cd forkfile
date > RELEASE
git add .
git commit -am "Forkfile"
git push
cd ..

[[ ! -d php-package ]] && git clone https://github.com/javanile/php-package
cd php-package
date > RELEASE
git add .
git commit -am "Forkfile"
git push
cd ..

[[ ! -d mysql-import ]] && git clone https://github.com/javanile/mysql-import
cd mysql-import
date > RELEASE
echo ""
echo ""
echo "====[ FORK.SH ]===="
../../../fork.sh
cd ..
