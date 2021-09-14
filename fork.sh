#!/usr/bin/env bash

##
# FORK.SH
#
# Maintenance strategy for prototype-based projects.
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

#debug() { echo "DEBUG ERROR [$1]: $2"; }
#trap 'debug ${LINENO} "$BASH_COMMAND"' 0

VERSION="0.3.0"

workdir=${PWD}

##
# Print-out usage message and exit
##
fork_usage () {
    echo "Usage: ./fork.sh [OPTION]..."
    echo ""
    echo "Parse Forkfile to align other files by a remote source"
    echo ""
    echo "List of available options"
    echo "  -f, --from REPOSITORY    Set REPOSITORY as remote source"
    echo "  -u, --update REPOSITORY  Update REPOSITORY instead current directory"
    echo "  -b, --branch BRANCH      Set BRANCH for remote source instead of default"
    echo "  -h, --hard               Display current version"
    echo "  -v, --verbose            Display current version"
    echo "  --version                Display current version"
    echo "  --help                   Display this help and exit"
    echo ""
    echo "Documentation can be found at https://github.com/javanile/fork.sh"
    exit 1
}

##
#
##
fork_log () {
    echo " ---> $@"
}

##
#
##
fork_error() {
    echo -e "${escape}[1m${escape}[31m[ERROR]${escape}[0m ${@}"
    exit 1
}

##
#
##
fork_debug () {
    echo -e "${escape}[1m${escape}[33mDEBUG>${escape}[0m ${@}"
}

case "$(uname -s)" in
    Darwin*)
        getdep=''
        getopt='/usr/local/opt/gnu-getopt/bin/getopt'
        escape='\x1B'
        ;;
    Linux|*)
        [ -x /bin/getopt ] && getopt=/bin/getopt || getopt=/usr/bin/getopt
        escape='\e'
        ;;
esac

hard=
verbose=
local_from=
local_branch=
local_update=
package=^[A-Za-z_\.-]+/[A-Za-z_\.-]+$
options=$(${getopt} -n fork.sh -o f:u:b:hv -l from:,update:,branch:,hard,verbose,version,help -- "$@")

eval set -- "${options}"

while true; do
    case "$1" in
        -f|--from) shift; local_from=$1 ;;
        -u|--update) shift; local_update=$1 ;;
        -b|--branch) shift; local_branch=$1 ;;
        -h|--hard) hard=1 ;;
        -v|--verbose) verbose=1 ;;
        --version) echo "FORK.SH version ${VERSION}"; exit ;;
        --help) usage; exit ;;
        --) shift; break ;;
    esac
    shift
done

if [[ $# -ne 0 ]]; then
    echo "fork.sh: unrecognized option '${@}'"
    usage
fi

##
#
##
fork_trace () {
    echo $1 >> ${trace}
}

##
# $1 - Arguments of FROM statement
##
fork_clone() {
    branch="$(echo "$1?" | cut -d'?' -f2)"
    repository="$(echo "$1?" | cut -d'?' -f1)"
    [[ -n "$2" ]] && branch="$2"
    [[ "${repository}" =~ ${package} ]] && repository=https://github.com/${repository}
    branch_info="'${branch}'"
    branch_option="-b ${branch}"
    [[ -z "${branch}" ]] && branch_info="default" && branch_option=""
    fork_log "Check '${repository}' due to integrity."
    [[ -n "${verbose}" ]] && echo -n "Refs: " && git ls-remote ${repository} | grep "${branch}" | tr '\t' ' '
    fork_log "Fetch '${repository}' from ${branch_info} branch."
    local tmpdir=$(mktemp -d -t fork-clone-dir-XXXXXXXXXX)
    cd ${tmpdir}
    git clone -q ${branch_option} "${repository}" LOCAL || true
    if [[ -d "${tmpdir}/LOCAL" ]]; then
        fork_parse REMOTE $1 ${tmpdir}/LOCAL
    else
        error "Problem while creating: ${tmpdir}/LOCAL"
    fi
    rm -fr ${tmpdir} ${tmpout}
}

##
#
##
fork_copy() {
    source=${1}
    target_name=${2}
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    target_dir="$(dirname "${target}")"
    override=$(grep -e "^COPY ${source}$" ${trace}) && true
    if [[ ! -f "${target}" ]] || [[ -n "${override}" ]] || [[ -n "${hard}" ]]; then
        fork_log "Coping '${source}' to '${target}' from '${PWD}'"
        fork_trace "COPY ${source}"
        [[ -d "${target_dir}" ]] || mkdir -p ${target_dir}
        cp -R ${source} ${target}
        chmod 777 ${target}
    else
        fork_log "Ignoring copy '${source}', use '--hard' if you require it."
    fi
}

##
#
##
fork_dircopy() {
    source=${1}
    target_name=${2}
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    target_dir="$(dirname "${target}")"
    override=$(grep -e "^DIRCOPY ${source}$" ${trace}) && true
    if [[ ! -d "${target}" ]] || [[ -n "${override}" ]] || [[ -n "${hard}" ]]; then
        fork_log "Coping directory '${source}' to '${target}' from '${PWD}'"
        fork_trace "DIRCOPY ${source}"
        [[ -d "${target_dir}" ]] || mkdir -p ${target_dir}
        [[ -d "${target}" ]] && cp -TRf ${source} ${target} || cp -Rf ${source} ${target}
        chmod 777 ${target}
    else
        fork_log "Ignoring copy '${source}', use '--hard' if you require it."
    fi
}

##
#
##
fork_touch() {
    target_name=${1}
    target=${workdir}/${target_name}
    target_dir="$(dirname "${target}")"
    fork_log "Touch '${target}' from '${PWD}'"
    [[ -d "${target_dir}" ]] || mkdir -p "${target_dir}"
    touch ${target}
    chmod 777 ${target}
}

##
#
##
fork_move() {
    source=${1}
    target_name=${2}
    if [[ -n "${2}" ]]; then
        target=${workdir}/${target_name}/
        target_dir="$(dirname "${target}")/"
        fork_log "Move '${source}' to '${target}' from '${PWD}'"
        echo mv "${source}" "${target_dir}"
    else
        fork_log "Ignore move '${source}' due to missing destination."
    fi
}

##
#
##
fork_merge() {
    source=${1}
    target_name=${2}
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    fork_log "Merging '${source}' to '${target}' from '${PWD}'"
    tmp=$(mktemp -t merge-diff-XXXXXXXXXX)
    [[ -f "${target}" ]] || touch "${target}"
    diff --line-format %L ${target} ${source} > ${tmp} || true
    cp ${tmp} ${target}
    rm ${tmp}
}

##
# PROTOTYPE <remote_file> <local_file>
# Use a <remote_file> as template to create new <local_file> into LOCAL with environment variables replacement.
##
fork_prototype() {
    local source="${1}"
    local target_name="${2}"
    [[ -z ${target_name} ]] && target_name=${1}
    target=${workdir}/${target_name}
    target_dir="$(dirname "${target}")"
    override=$(grep -e "^PROTOTYPE ${source}$" ${trace}) && true
    if [[ ! -f "${target}" ]] || [[ -n "${override}" ]] || [[ -n "${hard}" ]]; then
        fork_log "Prototype '${source}' to '${target}' from '${PWD}'"
        fork_trace "PROTOTYPE ${source}"
        [[ -d "${target_dir}" ]] || mkdir -p ${target_dir}
        envsubst < ${source} > ${target}
        chmod 777 ${target}
    else
        fork_log "Ignoring prototype '${source}', use '--hard' if you require it."
    fi
}

##
#
##
fork_source() {
    local source="${workdir}/${1}"
    if [[ -f "${source}" ]]; then
        fork_log "Sourcing '${source}'."
        source "${source}"
        export $(cut -d= -f1 "${source}")
    else
        fork_log "Ignore source '${source}'."
    fi
}

##
# $1 - Kind of source LOCAL or REMOTE
# $2 - Source identifier current path for LOCAL, repository FROM for REMOTE
# $3 - Working directory to process the parsing
##
fork_parse() {
    cd $3
    local temp_pwd=${PWD}
    #debug "Workdir: ${PWD}"
    if [[ -e Forkfile ]]; then
        local row=0
        local forkfile=$(mktemp -t forkfile-XXXXXXXXXX)
        export Forkfile_from=rbn
        envsubst < Forkfile > ${forkfile}
        while IFS= read line || [[ -n "${line}" ]]; do
            ((row=row+1))
            [[ -z "${line}" ]] && continue
            [[ "${line::1}" == "#" ]] && continue
            #echo ${line}
            instruction=$(echo ${line} | cut -d" " -f1)
            case "${1}_${instruction}" in
                LOCAL_DUMP|REMOTE_DUMP)
                    fork_log DUMP "${@}"
                    printenv | grep -E '^Forkfile_' | sort
                    ;;
                LOCAL_DEBUG|REMOTE_DEBUG)
                    fork_log ${line:6}
                    ;;
                LOCAL_FROM)
                    temp_pwd=${PWD}
                    if [[ -z "${local_from}" ]]; then
                        fork_clone ${line:5}
                    else
                        fork_log "Ignore LOCAL FROM due to command line '--from' option."
                        fork_clone ${local_from} ${local_branch}
                    fi
                    cd ${temp_pwd}
                    ;;
                REMOTE_FROM)
                    temp_pwd=${PWD}
                    fork_clone ${line:5}
                    cd ${temp_pwd}
                    ;;
                LOCAL_COPY)
                    fork_log "Skip COPY in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_COPY)
                    fork_copy ${line:5}
                    ;;
                LOCAL_DIRCOPY)
                    fork_log "Skip COPY in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_DIRCOPY)
                    fork_dircopy ${line:8}
                    ;;
                LOCAL_TOUCH)
                    fork_log "Skip COPY in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_TOUCH)
                    fork_touch ${line:6}
                    ;;
                LOCAL_MERGE)
                    fork_log "Skip MERGE in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_MERGE)
                    fork_merge ${line:6}
                    ;;
                LOCAL_PROTOTYPE)
                    fork_log "Skip PROTOTYPE in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_PROTOTYPE)
                    fork_prototype ${line:10}
                    ;;
                LOCAL_SOURCE)
                    fork_log "Skip SOURCE in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_SOURCE)
                    fork_source ${line:7}
                    ;;
                LOCAL_HAVE)
                    fork_log "Skip HAVE in LOCAL Forkfile line ${row}"
                    ;;
                REMOTE_HAVE)
                    fork_have ${line:5}
                    ;;
                #LOCAL_MOVE)
                #    fork_log "Skip MOVE in LOCAL Forkfile line ${row}"
                #    ;;
                #REMOTE_MOVE)
                #    fork_move ${line:5}
                #    ;;
                *)
                    fork_error "Forkfile parse error line ${row}: unknown instruction: ${instruction} on '$2'"
                    ;;
            esac
        done < ${forkfile}
        [[ -f ${forkfile} ]] && rm ${forkfile}
    elif [[ "$1" == "LOCAL" ]] && [[ ! -z "${local_from}" ]]; then
        fork_info "Creating Forkfile on ${PWD}"
        echo "FROM ${local_from} ${local_branch}" > Forkfile
        temp_pwd=${PWD}
        fork_clone ${local_from} ${local_branch}
        cd ${temp_pwd}
    else
        fork_log "Missing 'Forkfile' in '$3'."
    fi
}

##
#
##
fork_info() {
    echo "$1"
}

##
#
##
fork_exit() {
    echo "$2" >&2
    exit "$1"
}

##
#
##
main() {
    if [[ -z "$(command -v git)" ]]; then
        fork_exit 1 "Missing git command on your system."
    fi
    if [[ -z "$(command -v envsubst)" ]]; then
        fork_exit 1 "Missing envsubst command on your system."
    fi
    if [[ -n "${local_update}" ]]; then
        workdir="$(mktemp -d -t fork-update-dir-XXXXXXXXXX)/UPDATE"
        #git clone -q -b ${branch} ${local_update} ${workdir} || true
        git clone -q "${local_update}" "${workdir}" || true
        [[ -d "${workdir}" ]] || error "Problem while creating: ${local_update}"
    fi
    if [[ ! -d ${workdir}/.git ]]; then
        fork_exit 1 "This directory does not appear to be a git repository"
    fi
    local=$(git config --get remote.origin.url)
    if [[ -n "${local_branch}" ]] && [[ -z "${local_from}" ]]; then
        debug "set local_from by default"
        local_from=${local}
    fi
    if [[ ! -f Forkfile ]] && [[ ! -f Forkfile.conf ]] && [[ -z "${local_from}" ]]; then
        fork_exit 1 "Could not find Forkfile or Forkfile.conf in this directory"
    fi
    trace=$(mktemp -t fork-trace-XXXXXXXXXX)
    #echo "Forkfile scanning..."
    echo "START ${workdir}" > "${trace}"
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile: init" > /dev/null 2>&1 && true
    export Forkfile_workdir=${workdir}
    export Forkfile_dirname=$(dirname "${workdir}")
    export Forkfile_name=$(basename "${workdir}")
    export FORK_NAME="$(basename "${workdir}")"
    fork_parse LOCAL "${local}" "${workdir}"
    git add . > /dev/null 2>&1 && true
    git commit -am "Forkfile: done" > /dev/null 2>&1 && true
    if [[ -n "${local_update}" ]]; then
        git push --force
        rm -fr "${workdir}"
    fi
    rm "${trace}"
    echo "Done."
}

## Entry-point
main
