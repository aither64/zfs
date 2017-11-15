#!/bin/ksh -p
. $STF_SUITE/include/libtest.shlib

ZFS_USER=$(cat /tmp/zfs-uidgid-offset-test-user.txt)
TEST_UID=$(cat /tmp/zfs-uidgid-offset-test-uid.txt)
TEST_GID=$(cat /tmp/zfs-uidgid-offset-test-gid.txt)

[ $(get_prop uidoffset $TESTPOOL) == "0" ] || \
    log_fail "uidoffset does not default to 0"
[ $(get_prop gidoffset $TESTPOOL) == "0" ] || \
    log_fail "gidoffset does not default to 0"

POOLDIR=$(get_prop mountpoint $TESTPOOL)

log_must touch "$POOLDIR/test.txt"
[ $(stat -c %u:%g "$POOLDIR/test.txt") == "0:0" ] || \
    log_fail "shifts UIDs/GIDs by default"

log_must chown 50000:60000 "$POOLDIR/test.txt"
[ $(stat -c %u:%g "$POOLDIR/test.txt") == "50000:60000" ] || \
    log_fail "shifts UIDs/GIDs by default"

log_must mkdir "$POOLDIR/userdir"
log_must chown $TEST_UID:$TEST_GID "$POOLDIR/userdir"
log_must su $ZFS_USER -c "touch '$POOLDIR/userdir/test.txt'"
[ $(stat -c %u:%g "$POOLDIR/userdir/test.txt") == "$TEST_UID:$TEST_GID" ] || \
    log_fail "shifts UIDs/GIDs by default"

# TO TEST:
# default property values
# does not alter uids/gids by default
# cannot change properties while mounted
# can change while unmounted
# shifts uids/gids
# access/read from within/without of the UID/GID range
# offsets can be changed
# sending data stream without offsets

log_pass
