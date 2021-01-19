#!/usr/bin/env bash
set -e

source ./test/bootstrap.sh

bash ./fork.sh --update https://gitlab.com/javanile/fixtures/forkfile-test3.git
