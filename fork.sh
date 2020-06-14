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

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
#trap 'failure ${LINENO} "$BASH_COMMAND"' 0

VERSION="0.1.0"

workdir=${PWD}

##
#
##
usage () {
    echo "Usage: ./fork.sh [OPTION]..."
    echo ""
    echo "Executes FILE as a test case also collect each LCOV info and generate HTML report"
    echo ""
    echo "List of available options"
    echo "  -f, --from REPOSITORY   Coverage of every"
    echo "  -b, --branch BRANCH     Coverage of every (require: '--from')"
    echo "  -l, --log               Display log information"
    echo "  -h, --help              Display this help and exit"
    echo "  -v, --version           Display current version"
    echo ""
    echo "Documentation can be found at https://github.com/javanile/fork.sh"
}

##
#
##
log () {
    echo " ---> $@"
}

##
#
##
error () {
    echo -e "${escape}[1m${escape}[31mERROR${escape}[0m ${@}"
    exit 1
}

##
#
##
debug () {
    echo "DEBUG $@"
}

case "$(uname -s)" in
    Darwin*)
        getdep=''
        getopt='/usr/local/opt/gnu-getopt/bin/getopt'
        escape='\x1B'
        ;;
    Linux|*)
        getopt=/usr/bin/getopt
        escape='\e'
        ;;
esac

local_from=
local_branch=
package=^[A-Za-z_\.-]+/[A-Za-z_\.-]+$
options=$(${getopt} -n fork.sh -o f:b:vh -l from:,branch:,version,help -- "$@")

eval set -- "${options}"

while true; do
    case "$1" in
        -f|--from) shift; [[ "$1" =~ ${package} ]] && local_from=https://github.com/$1 || local_from=$1 ;;
        -b|--branch) shift; local_branch=$1 ;;
        -v|--version) echo "FORK.SH version ${VERSION}"; exit ;;
        -h|--help) usage; exit ;;
        --) shift; break ;;
    esac
    shift
done

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
    log "Fetching from '$1' at '${branch}' branch"
    tmp=$(mktemp -d -t fork-clone-XXXXXXXXXX)
    cd ${tmp}
    #git clone -b ${branch} $1 LOCAL > /dev/null 2>&1 && true
    git clone -b ${branch} $1 LOCAL || true
    parse REMOTE $1 ${tmp}/LOCAL
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
        log "Coping '${source}' to '${target}' from '${PWD}'"
        trace "COPY ${soucr}"
        cp -R ${source} ${target}
        chmod 777 ${target}
    fi
}

##
#
##
merge () {
    source=${1}
    target_name=${2}
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    log "Merging '${source}' to '${target}' from '${PWD}'"
    tmp=$(mktemp -t merge-diff-XXXXXXXXXX)
    diff --line-format %L ${target} ${source} > ${tmp} || true
    cp ${tmp} ${target}
    rm ${tmp}
}

##
#
##
parse () {
    cd $3
    #debug "Workdir: ${PWD}"
    if [[ -e Forkfile ]]; then
        local row=0
        local forkfile=${PWD}/Forkfile.0
        export Forkfile_from=rbn
        envsubst < Forkfile > ${forkfile}
        while IFS= read line || [[ -n "${line}" ]]; do
            ((row=row+1))
            [[ -z "${line}" ]] && continue
            [[ "${line::1}" == "#" ]] && continue
            instruction=$(echo ${line} | cut -d" " -f1)
            case "$1_${instruction}" in
                LOCAL_DUMP|REMOTE_DUMP)
                    log DUMP "${@}"
                    printenv | grep -E '^Forkfile_' | sort
                    ;;
                LOCAL_DEBUG|REMOTE_DEBUG)
                    log ${line:6}
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
                LOCAL_MERGE)
                    log "Skip MERGE in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_MERGE)
                    merge ${line:6}
                    ;;
                *)
                    error "Forkfile parse error line ${row}: unknown instruction: ${instruction}"
                    ;;
            esac
        done < ${forkfile}
        #[[ -f ${forkfile} ]] && rm ${forkfile}
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
    if [[ -z "$(command -v git)" ]]; then
        echo "fork.sh: missing 'git' command on your system." >&2
        exit 1
    fi
    if [[ -z "$(command -v envsubst)" ]]; then
        echo "fork.sh: missing 'envsubst' command on your system." >&2
        exit 1
    fi
    if [[ ! -d ${workdir}/.git ]]; then
        echo "fork.sh: not a git repository." >&2
        exit 1
    fi
    trace=${workdir}/Forkfile.trace
    local=$(git config --get remote.origin.url)
    echo "START ${workdir}" > ${trace}
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile start..." > /dev/null 2>&1 && true
    export Forkfile_workdir=${workdir}
    export Forkfile_dirname=$(dirname "${workdir}")
    export Forkfile_name=$(basename "${workdir}")
    parse LOCAL ${local} ${workdir}
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile close." > /dev/null 2>&1 && true
    rm ${trace}
    echo "Done."
}

## Entry-point
main
