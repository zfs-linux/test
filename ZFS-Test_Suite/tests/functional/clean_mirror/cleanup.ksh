#! /bin/ksh -p
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
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)cleanup.ksh	1.3	07/02/06 SMI"
#

DISKS="$@"
. $STF_SUITE/commands.cfg
. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/include/default_common_varible.kshlib
. ./default.cfg

verify_runnable "global"

$DF -F zfs -h | $GREP "$TESTFS " >/dev/null
[[ $? == 0 ]] && log_must $ZFS umount -f $TESTDIR
destroy_pool $TESTPOOL

# recreate and destroy a zpool over the disks to restore the partitions to
# normal
if [[ -n $SINGLE_DISK ]]; then
	log_must cleanup_devices $MIRROR_PRIMARY
else
	log_must cleanup_devices $MIRROR_PRIMARY $MIRROR_SECONDARY
fi
log_pass