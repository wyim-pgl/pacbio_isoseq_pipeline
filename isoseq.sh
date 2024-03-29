#!/bin/bash
#################################################################################
# Copyright (c) 2016-, Pacific Biosciences of California, Inc.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the
# disclaimer below) provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above
#  copyright notice, this list of conditions and the following
#  disclaimer in the documentation and/or other materials provided
#  with the distribution.
#
#  * Neither the name of Pacific Biosciences nor the names of its
#  contributors may be used to endorse or promote products derived
#  from this software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
# GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY PACIFIC
# BIOSCIENCES AND ITS CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PACIFIC BIOSCIENCES OR ITS
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#################################################################################
# author: Bo Han (bhan@pacb.com)

declare -xr PACKAGE_NAME="pacbio_isoseq_pipeline"
declare -xr CONTACT_EMAILS="bhan@pacb.com"

######
# OS #
######
if [[ `uname` == "Darwin" ]]; then
    echo "Mac is currently no supported" >&2 && exit 1;
fi

##########
# Config #
##########
declare -xr CALLED_PROGRAM_NAME=$(basename $0)
declare -xr PROGRAM_NAME=$(readlink -f ${0})
declare -xr PIPELINE_DIRECTORY=$(dirname ${PROGRAM_NAME})
declare -xr MYBIN=${PIPELINE_DIRECTORY}/bin
declare -xr PATH=${MYBIN}:$PATH

set -eu -o pipefail

################
# load modules #
################
. ${PIPELINE_DIRECTORY}/bin/color.sh
. ${PIPELINE_DIRECTORY}/bin/functions.sh
. ${PIPELINE_DIRECTORY}/config/config.sh

function usage {
    local YELLOW=$(echo -ne ${FONT_COLOR_YELLOW})
    local GREEN=$(echo -ne ${FONT_COLOR_GREEN})
    local RESET=$(echo -ne ${FONT_STYLE_RESET})
    local BOLD=$(echo -ne ${FONT_STYLE_BOLD})
    local CYAN=$(echo -ne ${FONT_COLOR_CYAN})
    local MAGENTA=$(echo -ne ${FONT_COLOR_MAGENTA})
    cat << EOF
=======================${BOLD}
${PACKAGE_NAME}
${RESET}=======================
This is a pipeline to run PacBio Iso-Seq pipeline from RS II cells (primary analysis) to a final report.

${YELLOW}[ annotation ]
    Prepare annotation files for a given eukaryotic genome
    usage:
        isoseq.sh anno -g hg38
        isoseq.sh anno -g mm10
        isoseq.sh anno -g dm6
    "isoseq.sh anno -h" for detailed usage


${GREEN}[ all ]
    CCS + classify + cluster + isoaux + report for eukaryotic species
    usage:
        isoseq.sh all -c sample_info.csv -o my_output -J my_job_name -E my@email.com
    "isoseq.sh all -h" for detailed usage

${CYAN}[ pro ]
    CCS + classify + cluster + isoaux + report for prokaryotic species
    usage:
        isoseq.sh all -c sample_info.csv -o my_output -J my_job_name -E my@email.com
    "isoseq.sh pro -h" for detailed usage

${MAGENTA}[ gather ]
    For sample sequenced with more than one cells, the user need to run this module
    to gather all the data into a new directory, which is then used in the csv file
    usage:
        isoseq.sh gather -o /path/to/new_cell -i /path/to/cell1 -i /path/to/cell2 -i /path/to/cell3
    Then use /path/to/new_cell in the sample.csv file for "all" or "pro" modules

${RESET}

EOF
}

if [[ $# -lt 1 ]]; then usage && exit 1; fi

##############
# validation #
##############
# check executables 
declare -a GLOBAL_REQUIRED_PROGRAMS=( 'awk' 'smrtshell' 'Rscript' )
for program in "${GLOBAL_REQUIRED_PROGRAMS[@]}"; do binCheck $program; done
# check user directory setup
declare -a GLOBAL_REQUIRED_DIRVAR=( 'RLIBDIR' 'SMRT_HOME' 'ANNOTATION_DIR' )
declare -x INDEX_DIR=${ANNOTATION_DIR}/index
declare -x GMAP_INDEX_DIR=${INDEX_DIR}/gmap_index
declare -x BWA_INDEX_DIR=${INDEX_DIR}/bwa_index
# mkdir -p ${GMAP_INDEX_DIR} ${BWA_INDEX_DIR}

########
# Args #
########
declare SUBPROGRAM=$(echo ${1} | tr '[A-Z]' '[a-z]')
case $SUBPROGRAM in
    all)
        shift && bash _all.sh "$@" ;;
    pro)
        shift && bash _pro.sh "$@" ;;
    anno|annotation)
        shift && bash _anno.sh "$@";;
    gather)
        shift && bash _gather.sh "$@";;
    *)
        echo2 "unrecognized option \"${1}\"" error;;
esac