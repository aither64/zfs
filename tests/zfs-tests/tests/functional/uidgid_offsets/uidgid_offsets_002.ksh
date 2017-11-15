#!/bin/ksh -p
. $STF_SUITE/include/libtest.shlib

ZFS_USER=$(cat /tmp/zfs-uidgid-offset-test-user.txt)
TEST_UID=$(cat /tmp/zfs-uidgid-offset-test-uid.txt)
TEST_GID=$(cat /tmp/zfs-uidgid-offset-test-gid.txt)

FSDIR=$(get_prop mountpoint $TESTPOOL/$TESTFS)

# uidoffset and gidoffset can be changed only when the fs
# is not mounted
log_mustnot zfs set uidoffset=1234 $TESTPOOL/$TESTFS/both
log_mustnot zfs set gidoffset=5678 $TESTPOOL/$TESTFS/both
log_must zfs unmount $TESTPOOL/$TESTFS/both
log_must zfs set uidoffset=1234 $TESTPOOL/$TESTFS/both
log_must zfs set gidoffset=5678 $TESTPOOL/$TESTFS/both
log_must zfs mount $TESTPOOL/$TESTFS/both

# both properties should be inheritable
[ $(get_prop uidoffset $TESTPOOL/$TESTFS/both/child) == "1234" ] || \
    log_fail "uidoffset is not inherited"
[ $(get_prop gidoffset $TESTPOOL/$TESTFS/both/child) == "5678" ] || \
    log_fail "gidoffset is not inherited"

# accessing the fs with a user with uid/gid below the offset
log_must touch "$FSDIR/both/test.txt"
owner=$(stat -c %u:%g "$FSDIR/both/test.txt")
[ "$owner" == "1234:5678" ] || \
    log_fail "does not shift UIDs/GIDs for new files: expected 1234:5678, got $owner"

log_must chown 500:600 "$FSDIR/both/test.txt"
owner=$(stat -c %u:%g "$FSDIR/both/test.txt")
[ "$owner" == "$((500+1234)):$((600+5678))" ] || \
    log_fail "shifts UIDs/GIDs in setattr: expected $((500+1234)):$((600+5678)), got $owner"

# accessing the fs with a user with uid/gid greater or equal to the offset
log_must mkdir "$FSDIR/both/userdir"
log_must chown $TEST_UID:$TEST_GID "$FSDIR/both/userdir"
owner=$(stat -c %u:%g "$FSDIR/both/userdir")
[ "$owner" == "$TEST_UID:$TEST_GID" ] || \
    log_fail "does not shift UIDs/GIDs: expected $TEST_UID:$TEST_GID, got $owner"

log_must su $ZFS_USER -c "touch '$FSDIR/both/userdir/test.txt'"
owner=$(stat -c %u:%g "$FSDIR/both/userdir/test.txt")
[ "$owner" == "$TEST_UID:$TEST_GID" ] || \
    log_fail "does not shift UIDs/GIDs: expected $TEST_UID:$TEST_GID, got $owner"

log_must zfs unmount $TESTPOOL/$TESTFS/both
log_must zfs set uidoffset=0 gidoffset=0 $TESTPOOL/$TESTFS/both
log_must zfs mount $TESTPOOL/$TESTFS/both

owner=$(stat -c %u:%g "$FSDIR/both/test.txt")
[ "$owner" == "500:600" ] || \
    log_fail "UID/GID is persisted with an offset: expected 500:600, got $owner"

owner=$(stat -c %u:%g "$FSDIR/both/userdir/test.txt")
[ "$owner" == "$(($TEST_UID-1234)):$(($TEST_GID-5678))" ] || \
    log_fail "UID/GID is persisted with an offset: expected $(($TEST_UID-1234)):$(($TEST_GID-5678))"

log_pass
