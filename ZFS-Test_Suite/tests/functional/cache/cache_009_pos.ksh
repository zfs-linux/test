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
# ident	"@(#)cache_009_pos.ksh	1.2	09/05/19 SMI"
#

#. $STF_SUITE/tests/functional/cache/cache.kshlib
. /home/kqinfo/ZFS-test/ZFS-Test_Suite/tests/functional/cache/cache.kshlib
. /home/kqinfo/ZFS-test/ZFS-Test_Suite/tests/functional/cache/cache.cfg
. /home/kqinfo/ZFS-test/ZFS-Test_Suite/include/default_common_varible.kshlib
. /home/kqinfo/ZFS-test/ZFS-Test_Suite/include/libtest.kshlib
. /home/kqinfo/ZFS-test/ZFS-Test_Suite/commands.cfg

#################################################################################
#
# __stc_assertion_start
#
# ID: cache_009_pos
#
# DESCRIPTION:
#	Offline and online a cache device succeed.
#
# STRATEGY:
#	1. Create pool with mirror cache devices.
#	2. Offine and online a cache device
#	3. Display pool status
#	4. Destroy and loop to create pool with different configuration.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2008-04-24)
#
# __stc_assertion_end
#
################################################################################
if [[ $# -ne 2 ]];then
	echo "Usage : Two </dev> disk must"
	exit
fi
verify_runnable "global"
verify_disk_count "$LDEV2"
VDIR=`ls / | grep "disk" | tail -1`
log_assert "Offline and online a cache device succeed."
log_onexit cleanup

for type in "" "mirror" "raidz" "raidz2"
do
	#log_must $ZPOOL create $TESTPOOL $type $VDEV \
	#	cache $LDEV $LDEV2
	log_must $ZPOOL create $TESTPOOL $type /$VDIR/a /$VDIR/b /$VDIR/c cache $1 $2

	#ldev=$(random_get $LDEV $LDEV2)
	#log_must $ZPOOL offline $TESTPOOL $ldev
	log_must $ZPOOL offline $TESTPOOL $1 $2
	log_must display_status $TESTPOOL
	#log_must verify_cache_device $TESTPOOL $ldev 'OFFLINE' ''
	#log_must verify_cache_device $TESTPOOL  $1 $2 'OFFLINE' ''
	verify_cache_device $TESTPOOL  $1 $2 'OFFLINE' ''

	#log_must $ZPOOL online $TESTPOOL $ldev
	log_must $ZPOOL online $TESTPOOL $1 $2
	#log_must display_status $TESTPOOL
	#log_must verify_cache_device $TESTPOOL $ldev 'ONLINE' ''
	#log_must verify_cache_device $TESTPOOL $1 $2 'ONLINE' ''
	verify_cache_device $TESTPOOL $1 $2 'ONLINE' ''

	log_must umount $TESTPOOL
	log_must $ZPOOL destroy -f $TESTPOOL
done

log_pass "Offline and online a cache device succeed."