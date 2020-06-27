#!/usr/bin/env bash

##
# FORK.SH
#
# Project prototyping special.
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
trace=$(mktemp -t fork-trace-XXXXXXXXXX)

export FORKFILE_LOCAL_DIRNAME=$(dirname "${PWD}")
export FORKFILE_LOCAL_BASENAME=$(basename "${PWD}")

##
#
##
usage () {
    echo "Usage: ./fork.sh [OPTION]..."
    echo ""
    echo "Parse Forkfile to align other files by a remote source"
    echo ""
    echo "List of available options"
    echo "  -f, --from REPOSITORY   Set REPOSITORY as remote source"
    echo "  -b, --branch BRANCH     Set BRANCH for remote source instead of default"
    echo "  -h, --help              Display this help and exit"
    echo "  -v, --version           Display current version"
    echo ""
    echo "Documentation can be found at https://github.com/javanile/fork.sh"
    exit 1
}

##
#
##
debug () {
    echo " ---> $@"
}

##
#
##
error () {
    echo "[ERR] $1"
    exit 1
}

##
#
##
log () {
    echo "[LOG] $@"
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

if [[ $# -ne 0 ]]; then
    echo "fork.sh: unrecognized option '${@}'"
    usage
fi

if [[ ! -z "${local_branch}" ]] && [[ -z "${local_from}" ]]; then
    error "Required '--from' option with '--branch'"
fi



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
    debug "Fetching '$1' from '${branch}' branch"
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
    source=${1}
    target_name=${2}
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    override=$(grep -e "^COPY ${source}$" ${trace}) && true
    if [[ ! -f "${target}" ]] || [[ ! -z "${override}" ]]; then
        debug "Coping '${source}' to '${target}' from '${PWD}'"
        trace "COPY ${soucr}"
        cp -R ${source} ${target}
        chmod 777 ${target}
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
        forkfile=${PWD}/Forkfile.0
        export FORKFILE_REMOTE_BASENAME=rbn
        envsubst < Forkfile > ${forkfile}
        while IFS= read line || [[ -n "${line}" ]]; do
            [[ -z "${line}" ]] && continue
            [[ "${line::1}" == "#" ]] && continue
            instruction=$(echo ${line} | cut -d" " -f1)
            case "$1_${instruction}" in
                LOCAL_DEBUG|REMOTE_DEBUG)
                    debug ${line:6}
                    ;;
                LOCAL_FROM)
                    temp_pwd=${PWD}
                    if [[ -z "${local_from}" ]]; then
                        clone ${line:5}
                    else
                        log "Ignore LOCAL FROM due to command line '--from' option."
                        clone ${local_from} ${local_branch}
                    fi
                    cd ${temp_pwd}
                    ;;
                REMOTE_FROM)
                    temp_pwd=${PWD}
                    clone ${line:5}
                    cd ${temp_pwd}
                    ;;
                LOCAL_COPY)
                    log "Skip COPY in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_COPY)
                    copy ${line:5}
                    ;;
                *)
                    error "Forkfile parse error line ${row}: unknown instruction: ${instruction}"
                    ;;
            esac
        done < ${forkfile}
        [[ -f ${forkfile} ]] && rm ${forkfile}
    elif [[ "$1" == "LOCAL" ]] && [[ ! -z "${local_from}" ]]; then
        log "Write new 'Forkfile' on '${PWD}'"
        echo "FROM ${local_from} ${local_branch}" > Forkfile
        temp_pwd=${PWD}
        clone ${local_from} ${local_branch}
        cd ${temp_pwd}
    else
        log "Missing 'Forkfile' in '$3'."
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
    rm ${trace}
    log "Done."
}

## Entry-point
main
