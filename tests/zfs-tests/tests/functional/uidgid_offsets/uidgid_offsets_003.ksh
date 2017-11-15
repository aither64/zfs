#!/bin/ksh -p
. $STF_SUITE/include/libtest.shlib

ZFS_USER=$(cat /tmp/zfs-uidgid-offset-test-user.txt)
TEST_UID=$(cat /tmp/zfs-uidgid-offset-test-uid.txt)
TEST_GID=$(cat /tmp/zfs-uidgid-offset-test-gid.txt)
FSDIR=$(get_prop mountpoint $TESTPOOL/$TESTFS)

log_must zfs unmount $TESTPOOL/$TESTFS/both
log_must zfs set uidoffset=1234 $TESTPOOL/$TESTFS/both
log_must zfs set gidoffset=5678 $TESTPOOL/$TESTFS/both
log_must zfs mount $TESTPOOL/$TESTFS/both
log_must zfs create $TESTPOOL/$TESTFS/both.noprop
log_must zfs create $TESTPOOL/$TESTFS/both.withprop
log_must zfs snapshot $TESTPOOL/$TESTFS/both@snap

log_must zfs send $TESTPOOL/$TESTFS/both@snap | zfs recv -F $TESTPOOL/$TESTFS/both.noprop
owner=$(stat -c %u:%g "$FSDIR/both.noprop/test.txt")
[ "$owner" == "500:600" ] || \
    log_fail "UID/GID is persisted with an offset: expected 500:600, got $owner"

owner=$(stat -c %u:%g "$FSDIR/both.noprop/userdir/test.txt")
[ "$owner" == "$(($TEST_UID-1234)):$(($TEST_GID-5678))" ] || \
    log_fail "UID/GID is persisted with an offset: expected $(($TEST_UID-1234)):$(($TEST_GID-5678))"

log_must zfs send -p $TESTPOOL/$TESTFS/both@snap | zfs recv -F $TESTPOOL/$TESTFS/both.withprop
owner=$(stat -c %u:%g "$FSDIR/both.withprop/test.txt")
[ "$owner" == "$((500+1234)):$((600+5678))" ] || \
    log_fail "shifts UIDs/GIDs in setattr: expected $((500+1234)):$((600+5678)), got $owner"

owner=$(stat -c %u:%g "$FSDIR/both.withprop/userdir")
[ "$owner" == "$TEST_UID:$TEST_GID" ] || \
    log_fail "does not shift UIDs/GIDs: expected $TEST_UID:$TEST_GID, got $owner"

owner=$(stat -c %u:%g "$FSDIR/both.withprop/userdir/test.txt")
[ "$owner" == "$TEST_UID:$TEST_GID" ] || \
    log_fail "does not shift UIDs/GIDs: expected $TEST_UID:$TEST_GID, got $owner"

log_pass
