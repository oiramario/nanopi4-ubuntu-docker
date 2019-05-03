setenv bootargs root=/dev/mmcblk1p6 rootfstype=ext4 rw rootwait

#               -start-       -size-               -padding-          -next-
# origin        0x00000000    0x00080000 (512K)    0x00000000         0x00080000
# kernel        0x00080000    0x01200000 (18M)     0x00200000 (2M)    0x01400000
# fdt           0x01400000    0x00200000 (2M)      0x00100000 (1M)    0x01700000
# initrd        0x01700000    0x00200000 (2M)      0x00100000 (1M)    0x02000000

setenv fit_addr 0x2000000
ext4load mmc 0:5 $fit_addr /fit.itb
bootm $fit_addr
