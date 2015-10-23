#!/sbin/sh
#ramdisk_gov_sed.sh by show-p1984
#Features:
#extracts ramdisk
#finds busbox in /system or sets default location if it cannot be found
#add init.d support if not already supported
#removes forced encryption
#disables mpdecision
#repacks the ramdisk

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /

#remove cmdline parameters we do not want
#maxcpus=2 in this case, which limits smp activation to the first 2 cpus
echo $(cat /tmp/boot.img-cmdline | sed -e 's/maxcpus=[^ ]\+//')>/tmp/boot.img-cmdline

#Don't force encryption
if  grep -qr forceencrypt /tmp/ramdisk/fstab.shamu; then
   sed -i "s/forceencrypt/encryptable/" /tmp/ramdisk/fstab.shamu
fi

#Gain write access on /system
if  grep -qr ro.secure=1 /tmp/ramdisk/default.prop; then
   sed -i "s/ro.secure=1/ro.secure=0/" /tmp/ramdisk/default.prop
fi

#remove verify
if  grep -qr verity_load_state /tmp/ramdisk/init.shamu.rc; then
 sed -i "s/verity_load_state/#verity_load_state/" /tmp/ramdisk/init.shamu.rc
fi
if  grep -qr verity_update_state /tmp/ramdisk/init.shamu.rc; then
 sed -i "s/verity_update_state/#verity_update_state/" /tmp/ramdisk/init.shamu.rc
fi

#add init.d support if not already supported
#this is no longer needed as the ramdisk now inserts our modules, but we will
#keep this here for user comfort, since having run-parts init.d support is a
#good idea anyway.
found=$(find /tmp/ramdisk/init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
	#append the new lines for this option at the bottom
        echo "" >> /tmp/ramdisk/init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> /tmp/ramdisk/init.rc
        echo "    oneshot" >> /tmp/ramdisk/init.rc
        echo "    class late_start" >> /tmp/ramdisk/init.rc
        echo "    user root" >> /tmp/ramdisk/init.rc
        echo "    group root" >> /tmp/ramdisk/init.rc
fi

#add benzoCore's init script without replacing all of init.shamu.rc.
foundbrc=$(find /tmp/ramdisk/init.shamu.rc -type f | xargs grep -oh "import init.benzo.rc");
if [ "$foundbrc" != 'import init.benzo.rc' ]; then
	sed -i 's/import init.shamu.diag.rc/import init.benzo.rc'"\n"'import init.shamu.diag.rc/g' /tmp/ramdisk/init.shamu.rc
fi

#copy fstab
cp /tmp/fstab.shamu /tmp/ramdisk/fstab.shamu
chmod 750 /tmp/ramdisk/fstab.shamu

#copy custom init.shamu.power.rc
cp /tmp/init.shamu.power.rc /tmp/ramdisk/init.shamu.power.rc
chmod 750 /tmp/ramdisk/init.shamu.power.rc

#copy init.benzo.rc
cp /tmp/init.benzo.rc /tmp/ramdisk/init.benzo.rc
chmod 750 /tmp/ramdisk/init.benzo.rc


rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/
find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
cd /
rm -rf /tmp/ramdisk

