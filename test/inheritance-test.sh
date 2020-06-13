#!/usr/bin/env bash

git config credential.helper 'cache --timeout=3000'

cd test/fixtures

[[ -d forkfile ]] && git clone https://github.com/javanile/forkfile
cd forkfile
git add .
git commit -am "Forkfile"
git push
cd ..

[[ -d php-package ]] && git clone https://github.com/javanile/php-package
cd php-package
git add .
git commit -am "Forkfile"
git push
cd ..

[[ -d mysql-import ]] && git clone https://github.com/javanile/mysql-import
cd mysql-import
echo ""
echo ""
echo "====[ FORK.SH ]===="
../../../fork.sh
cd ..
