#!/bin/bash
#
#set -x

source scripts/functions/common.sh


download_dir=$(pwd)/downloads
[ ! -d ${download_dir} ] && mkdir -p ${download_dir}

packages_dir=$(pwd)/packages
[ ! -d ${packages_dir} ] && mkdir -p ${packages_dir}

github_url="https://github.com.cnpmjs.org"

update_sources()
{
    cd ${download_dir}

    local gits=(
    "u-boot,rockchip-linux/u-boot.git,stable-4.4-rk3399-linux"
    "kernel,friendlyarm/kernel-rockchip.git,nanopi4-linux-v4.4.y"
    "busybox,mirror/busybox.git,1_31_stable"
    "gdb,bminor/binutils-gdb.git,gdb-8.3-branch"
    "libmali,rockchip-linux/libmali.git,rockchip"
    "libdrm,rockchip-linux/libdrm-rockchip.git,rockchip-2.4.97"
    "libusb,libusb/libusb.git,v1.0.23"
    "librealsense,IntelRealSense/librealsense.git,v2.35.0"
    "ogles-cube,oiramario/gbm-drm-gles-cube.git,master"
    "rkbin,rockchip-linux/rkbin.git,stable-4.4-rk3399-linux"
    "rk-rootfs-build,rockchip-linux/rk-rootfs-build.git,master"
    "mpp,rockchip-linux/mpp.git,develop"
    "x264,mirror/x264.git,stable"
    "ffmpeg,FFmpeg/FFmpeg.git,release/4.2"
    "alsa-lib,alsa-project/alsa-lib.git,v1.2.2"
    "mpv,rockchip-linux/mpv.git,master"
    "gl4es,ptitSeb/gl4es.git,v1.1.2"
    "k380-function-keys-conf,jergusg/k380-function-keys-conf.git,master"
    )
    for i in ${gits[@]}
    do
        local str=($i)
        local arr=(${str//,/ })

        local dir=${arr[0]}
        local url="${github_url}/${arr[1]}"
        local branch=${arr[2]}

        echo
        info_msg "checking ${dir}"
        if [ ! -d ${dir} ];then
            git clone --depth 1 --branch ${branch} --single-branch ${url} ${dir}
        else
            local ret=$(git -C ${dir} pull)
            if [ $? -eq 0 ]; then
                if [[ ${ret} =~ "Already up to date." ]];then
                    echo "up-to-date sources"
                    if [ -f ${packages_dir}/${dir}.tar.gz ]; then
                        echo "up-to-date package"
                        continue
                    fi
                fi
            else
                error_msg "operation failed"
                continue
            fi
        fi

        if [ $? -eq 0 ] ; then
            info_msg "packaging ${dir}"
            local exclude="--exclude-vcs"
            if [ ${dir} = "rk-rootfs-build" ];then
                exclude+=" \
                    --exclude=*.md \
                    --exclude=${dir}/mk-*.sh \
                    --exclude=overlay-firmware/usr/share/npu_fw \
                    --exclude=overlay-firmware/usr/share/npu_fw_pcie \
                    --exclude=packages \
                    --exclude=overlay-debug \
                    --exclude=packages-patches \
                    --exclude=ubuntu-build-service"
            elif [ $dir = "libmali" ];then
                exclude+=" \
                    --exclude=lib/arm-linux-gnueabihf \
                    --exclude=lib/aarch64-linux-gnu/libmali-bifrost-* \
                    --exclude=lib/aarch64-linux-gnu/libmali-utgard-* \
                    --exclude=lib/aarch64-linux-gnu/libmali-midgard-t86x-r9p0-* \
                    --exclude=lib/aarch64-linux-gnu/libmali-midgard-t86x-r13p0-* \
                    --exclude=lib/aarch64-linux-gnu/libmali-midgard-t86x-r14p0-r0p0-fbdev.so \
                    --exclude=lib/aarch64-linux-gnu/libmali-midgard-t86x-r14p0-r0p0-wayland-gbm.so \
                    --exclude=lib/aarch64-linux-gnu/libmali-midgard-t86x-r14p0-r0p0-x11.so"
            fi

            eval tar -czf ${packages_dir}/${dir}.tar.gz $exclude -C . ${dir} --checkpoint=1000 --checkpoint-action=dot --totals
        fi
    done
}


update_packages()
{
    local tars=(
    "ubuntu-rootfs.tar.gz,http://cdimage.ubuntu.com/ubuntu-base/releases/bionic/release/ubuntu-base-18.04.4-base-arm64.tar.gz"
    )
    for i in ${tars[@]}
    do
        local str=($i)
        local arr=(${str//,/ })

        local name=${arr[0]}
        local url=${arr[1]}

        echo
        info_msg "checking ${name}"

        if [ ! -f ${download_dir}/${name} ]; then
            rm -rf /tmp/${name}
            wget -O /tmp/${name} ${url}
            if [ $? -eq 0 ] ; then
                cp /tmp/${name} ${download_dir}/${name}
            else
                error_msg "operation failed"
                continue
            fi
        else
            echo "exits"
        fi
        cp -f ${download_dir}/${name} ${packages_dir}/${name}
    done
}


######################################################################################
update_sources
update_packages


echo
info_msg "Done."
ls ${packages_dir} -lh
