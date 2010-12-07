#!/bin/ksh -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)zpool_add_006_pos.ksh	1.5	09/06/22 SMI"
#
. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/tests/functional/cli_root/zpool_add/zpool_add.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID: zpool_add_006_pos
#
# DESCRIPTION:
# 'zpool add [-f]' can add large numbers of file-in-zfs-filesystem-based vdevs 
# to the specified pool without any errors.
#
# STRATEGY:
# 1. Create assigned number of files in ZFS filesystem as vdevs and use the first
# file to create a pool
# 2. Add other vdevs to the pool should get success
# 3  Fill in the filesystem and create a partially written file 
# as vdev
# 4. Add the new file into the pool should be failed.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2005-10-09)
#
# __stc_assertion_end
#
################################################################################

log_notinuse "bug 6391576"

verify_runnable "global"

function cleanup
{
	poolexists $TESTPOOL1 && \
		destroy_pool $TESTPOOL1

	datasetexists $TESTPOOL/$TESTFS && \
		log_must $ZFS destroy -f $TESTPOOL/$TESTFS
	poolexists $TESTPOOL && \
		destroy_pool $TESTPOOL

	if [[ -d $TESTDIR ]]; then
		log_must $RM -rf $TESTDIR
	fi

	partition_cleanup
}

	
#
# Create a pool and fs on the assigned disk, and dynamically create large 
# numbers of files as vdevs.(the default value is <VDEVS_NUM>) 
# the first file will be used to create a pool for other vdevs to be added into
#

function setup_vdevs #<disk> 
{
	typeset disk=$1
	typeset -i count=0
	typeset -i largest_num=0
	typeset -i slicesize=0
	typeset vdev=""
	

	#
	# Get disk size for zfs filesystem
	#
	create_pool foo $disk
	log_must $ZFS create foo/fs
	typeset -i fs_size=$(get_prop "available" foo/fs)
	destroy_pool foo

	(( largest_num = fs_size / (1024 * 1024 * 64) )) #64m is the minmum size for pool
	if (( largest_num < $VDEVS_NUM )); then
		(( vdevs_num=largest_num - largest_num/40 )) # minus $largest_num/40 to leave 
							      #2.5% space for metadata.
		file_size=64
		vdev=$disk
	else
		vdevs_num=$VDEVS_NUM
		(( file_size = fs_size / (1024 * 1024 * (vdevs_num + vdevs_num/40)) ))
		if (( file_size > FILE_SIZE )); then
			file_size=$FILE_SIZE
		fi
		(( slice_size = file_size * (vdevs_num + vdevs_num/40) )) # plus $vdevs_num/40 to provide 
								#enough space for metadata. 
		set_partition 0 "" ${slice_size}m $disk
		vdev=${disk}s0
        fi

	create_pool $TESTPOOL $vdev  
	[[ -d $TESTDIR ]] && \
		log_must $RM -rf $TESTDIR  
        log_must $MKDIR -p $TESTDIR  
        log_must $ZFS create $TESTPOOL/$TESTFS 
        log_must $ZFS set mountpoint=$TESTDIR $TESTPOOL/$TESTFS  

# Create a pool first using the first file, and make subsequent files ready
# as vdevs to add to the pool

	log_must $MKFILE ${file_size}m ${TESTDIR}/file.$count
	create_pool "$TESTPOOL1" "${TESTDIR}/file.$count"
	log_must poolexists "$TESTPOOL1"

	while (( count < vdevs_num )); do # minus 1 to avoid space non-enough
		(( count = count + 1 ))
		log_must $MKFILE ${file_size}m ${TESTDIR}/file.$count  
		vdevs_list="$vdevs_list ${TESTDIR}/file.$count"
	done
}

log_assert " 'zpool add [-f]' can add large numbers of vdevs to the specified" \
	   " pool without any errors."
log_onexit cleanup

if [[ $DISK_ARRAY_NUM == 0 ]]; then
        disk=$DISK
else
        disk=$DISK0
fi

vdevs_list=""
vdevs_num=$VDEVS_NUM
file_size=$FILE_SIZE

setup_vdevs $disk
log_must $ZPOOL add -f "$TESTPOOL1" $vdevs_list
log_must iscontained "$TESTPOOL1" "$vdevs_list"

(( file_size = file_size * (vdevs_num/40 + 1 ) ))
log_mustnot $MKFILE ${file_size}m ${TESTDIR}/broken_file 

log_mustnot $ZPOOL add -f "$TESTPOOL1" ${TESTDIR}/broken_file
log_mustnot iscontained "$TESTPOOL1" "${TESTDIR}/broken_file"

log_pass "'zpool successfully add [-f]' can add large numbers of vdevs to the" \
	 "specified pool without any errors."