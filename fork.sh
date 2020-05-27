#!/usr/bin/env bash

##
# FORK.SH
#
# The best way to zip your source code.
#
# Copyright (c) 2020 Francesco Bianco <bianco@javanile.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##

[[ -z "${LCOV_DEBUG}" ]] || set -x

set -ef

VERSION="0.1.0"

workdir=${PWD}
trace=${PWD}/Forkfile.trace

##
#
##
usage () {
    echo "Usage: ./fork.sh [OPTION]..."
    echo ""
    echo "Executes FILE as a test case also collect each LCOV info and generate HTML report"
    echo ""
    echo "List of available options"
    echo "  -f, --from EXT     Coverage of every *.EXT file (default: sh)"
    echo "  -b, --branch EXT     Coverage of every *.EXT file (default: sh)"
    echo "  -h, --help              Display this help and exit"
    echo "  -v, --version           Display current version"
    echo ""
    echo "Documentation can be found at https://github.com/javanile/fork.sh"
}

case "$(uname -s)" in
    Darwin*)
        getopt=/usr/local/opt/gnu-getopt/bin/getopt
        escape='\x1B'
        ;;
    Linux|*)
        getopt=/usr/bin/getopt
        escape='\e'
        ;;
esac

local_from=
local_branch=
options=$(${getopt} -n fork.sh -o f:b:vh -l from:,branch:,version,help -- "$@")

eval set -- "${options}"

while true; do
    case "$1" in
        -f|--from) shift; local_from=$1 ;;
        -b|--branch) shift; local_branch=$1 ;;
        -v|--version) echo "FORK.SH version ${VERSION}"; exit ;;
        -h|--help) usage; exit ;;
        --) shift; break ;;
    esac
    shift
done

##
#
##
error () {
    echo "[ERROR] $1"
    exit 1
}

##
#
##
debug () {
    echo "[DEBUG] $1"
}

##
#
##
trace () {
    echo $1 >> ${trace}
}

##
#
##
clone () {
    branch=${2:-master}
    debug "Fetching from '$1' at '${branch}' branch"
    tmp=$(mktemp -d -t fork-clone-XXXXXXXXXX)
    cd ${tmp}
    git clone -b ${branch} $1 LOCAL  > /dev/null 2>&1 && true
    parse REMOTE ${tmp}/LOCAL $1
    rm -fr ${tmp}
}

##
#
##
copy () {
    source=${workdir}/$1
    override=$(grep -e "^COPY ${1}$" ${trace}) && true
    if [[ ! -f "${source}" ]] || [[ ! -z "${override}" ]]; then
        debug "Coping '$1' to '${workdir}' from '${PWD}'"
        trace "COPY $1"
        cp -R $1 ${workdir}/
        chmod 777 ${workdir}/$1
    fi
}

##
#
##
parse () {
    cd $2
    #debug "Workdir: ${PWD}"
    if [[ -e Forkfile ]]; then
        row=0
        while IFS= read line || [[ -n "${line}" ]]; do
            [[ -z "${line}" ]] && continue
            [[ "${line::1}" == "#" ]] && continue
            instruction=$(echo ${line} | cut -d" " -f1)
            case "$1_${instruction}" in
                "LOCAL_FROM")
                    temp_pwd=${PWD}
                    if [[ -z "${local_from}" ]]; then
                        clone ${line:5}
                    else
                        debug "Ignore LOCAL FROM due to command line '--from' option."
                        clone ${local_from} ${local_branch}
                    fi
                    cd ${temp_pwd}
                    ;;
                "REMOTE_FROM")
                    temp_pwd=${PWD}
                    clone ${line:5}
                    cd ${temp_pwd}
                    ;;
                "LOCAL_COPY")
                    debug "Skip COPY in LOCAL Forkfile line ${row}"
                    ;;
                "REMOTE_COPY")
                    copy ${line:5}
                    ;;
                *)
                    error "Forkfile parse error line ${row}: unknown instruction: ${instruction}"
                    ;;
            esac
        done < Forkfile
    elif [[ "$1" == "LOCAL" ]] && [[ ! -z "${local_from}" ]]; then
        debug "Write new 'Forkfile' on '${PWD}'"
        echo "FROM ${local_from} ${local_branch}" > Forkfile
        temp_pwd=${PWD}
        clone ${local_from} ${local_branch}
        cd ${temp_pwd}
    else
        debug "Missing 'Forkfile' in '$3'."
    fi
    #cd ${workdir}
}

##
#
##
main () {
    echo "START ${workdir}" > ${trace}
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile start..." > /dev/null 2>&1 && true
    parse LOCAL ${workdir} ${workdir}
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile close." > /dev/null 2>&1 && true
    #rm ${trace}
    debug "Done."
}

## Entry-point
main
