#
# This file is part of LSPosed.
#
# LSPosed is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# LSPosed is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LSPosed.  If not, see <https://www.gnu.org/licenses/>.
#
# Copyright (C) 2021 LSPosed Contributors
#

MODDIR=${0%/*}
cd "$MODDIR"
# post-fs-data.sh may be blocked by other modules. retry to start this
unshare --propagation slave -m sh -c "$MODDIR/daemon --from-service $@&"

#部分代码来源magiskhide and shamiko
#!/system/bin/sh
# Conditional MagiskHide properties

maybe_set_prop() {
    local prop="$1"
    local contains="$2"
    local value="$3"

    if [[ "$(getprop "$prop")" == *"$contains"* ]]; then
        resetprop "$prop" "$value"
    fi
}

check_reset_prop() {
  local NAME=$1
  local EXPECTED=$2
  local VALUE=$(resetprop $NAME)
  [ -z $VALUE ] || [ $VALUE = $EXPECTED ] || resetprop $NAME $EXPECTED
}

contains_reset_prop() {
  local NAME=$1
  local CONTAINS=$2
  local NEWVAL=$3
  [[ "$(resetprop $NAME)" = *"$CONTAINS"* ]] && resetprop $NAME $NEWVAL
}

# Magisk recovery mode
maybe_set_prop ro.bootmode recovery unknown
maybe_set_prop ro.boot.mode recovery unknown
maybe_set_prop vendor.boot.mode recovery unknown

# MIUI cross-region flash
maybe_set_prop ro.boot.hwc CN GLOBAL
maybe_set_prop ro.boot.hwcountry China GLOBAL

resetprop --delete ro.build.selinux

# SELinux permissive
if [[ "$(cat /sys/fs/selinux/enforce)" == "0" ]]; then
    chmod 640 /sys/fs/selinux/enforce
    chmod 440 /sys/fs/selinux/policy
fi

# Late props which must be set after boot_completed
{
    until [[ "$(getprop sys.boot_completed)" == "1" ]]; do
        sleep 1
    done

    # Avoid breaking Realme fingerprint scanners
    resetprop ro.boot.flash.locked 1

    # Avoid breaking Oppo fingerprint scanners
    resetprop ro.boot.vbmeta.device_state locked

    # Avoid breaking OnePlus display modes/fingerprint scanners
    resetprop vendor.boot.verifiedbootstate green

    # Safetynet (avoid breaking OnePlus display modes/fingerprint scanners on OOS 12)
    resetprop ro.boot.verifiedbootstate green
    resetprop ro.boot.veritymode enforcing
    resetprop vendor.boot.vbmeta.device_state locked

    check_reset_prop "ro.boot.vbmeta.device_state" "locked"
  check_reset_prop "ro.boot.verifiedbootstate" "green"
  check_reset_prop "ro.boot.flash.locked" "1"
  check_reset_prop "ro.boot.veritymode" "enforcing"
  check_reset_prop "ro.boot.warranty_bit" "0"
  check_reset_prop "ro.warranty_bit" "0"
  check_reset_prop "ro.debuggable" "0"
  check_reset_prop "ro.secure" "1"
  check_reset_prop "ro.adb.secure" "1"
  check_reset_prop "ro.build.type" "user"
  check_reset_prop "ro.build.tags" "release-keys"
  check_reset_prop "ro.vendor.boot.warranty_bit" "0"
  check_reset_prop "ro.vendor.warranty_bit" "0"
  check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
  check_reset_prop "vendor.boot.verifiedbootstate" "green"
  check_reset_prop "ro.secureboot.lockstate" "locked"

  # Realme special
  check_reset_prop "ro.boot.realmebootstate" "green"
  check_reset_prop "ro.boot.realme.lockstate" "1"

  # Hide that we booted from recovery when magisk is in recovery mode
  contains_reset_prop "ro.bootmode" "recovery" "unknown"
  contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
  contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

  resetprop --delete ro.build.selinux

    # Avoid breaking encryption, set shipping level to 32 for devices >=33 to allow for software attestation
    if [[ "$(getprop ro.product.first_api_level)" -ge 33 ]]; then
        resetprop ro.product.first_api_level 32
    fi
}&
#在这个脚本中， & 的作用是将其后面的命令放到后台执行。这样做的好处是让主程序可以继续执行，而不必等待后台任务完成。
#具体来说，这里的 & 与前面的 { } 一起使用，形成了一个后台进程。这个后台进程会持续检查 sys.boot_completed 属性是否已经设置为"1"。一旦设置为"1"，它会执行一系列的 resetprop 命令来设置各种属性值。
#由于这些 resetprop 操作可能需要一段时间才能完成，而且它们并不影响主程序的正常运行，所以将它们放到后台执行可以避免主程序被阻塞。
#总之， & 在这里的作用是启动一个新的后台进程，让后台进程独立地执行其中的命令，而不会影响主程序的执行流程。
