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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)cache_002_pos.ksh	1.1	08/05/14 SMI"
#

. $STF_SUITE/tests/functional/cache/cache.kshlib
. $STF_SUITE/tests/functional/cache/cache.cfg
. $STF_SUITE/include/default_common_varible.kshlib
. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/commands.cfg

#################################################################################
#
# __stc_assertion_start
#
# ID: cache_002_pos
#
# DESCRIPTION:
#	Adding a cache device to normal pool works.
#
# STRATEGY:
#	1. Create pool
#	2. Add cache devices with different configuration
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
if [[ $# -ne 1 ]] ; then
	echo "Usage : one < /dev disk > must"
	exit
fi
verify_runnable "global"
VDIR=`ls / | grep "disk" | tail -1`
log_assert "Adding a cache device to normal pool works."
log_onexit cleanup

for type in "" "mirror" "raidz" "raidz2"
do
	log_must $ZPOOL create -f $TESTPOOL $type /$VDIR/a /$VDIR/b /$VDIR/c
	log_must $ZPOOL add $TESTPOOL cache $1
	log_must display_status $TESTPOOL
	#typeset ldev=$(random_get $LDEV)
	typeset ldev=$1
	log_must verify_cache_device $TESTPOOL $ldev 'ONLINE'

	#log_must $ZPOOL remove $TESTPOOL $ldev
	log_must check_vdev_state $TESTPOOL $ldev ""

	log_must umount $TESTPOOL
	log_must $ZPOOL destroy -f $TESTPOOL
done

log_pass "Adding a cache device to normal pool works."
