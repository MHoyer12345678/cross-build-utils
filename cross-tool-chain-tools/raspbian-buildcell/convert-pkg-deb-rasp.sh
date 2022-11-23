#!/bin/bash

# convert-pkg-deb-rasp.sh <pkg_name>
# return codes: 0: everything fine, 1: error, 2: package skipped (not AMD64), 3: version conflict detected, package processed anyway

# - check if pkg is amd64 package. If not -> skip
# - get package  version from raspbian distro (armhf version)
# - download amd64 package from debian mirror
# - unpack amd64 package
# - change version in control file
# - repack amd64 package w/ new version in name

if [ $# -eq 0 ]; then
    echo "Name of package to convert missing"
    exit 1
fi

pkg_name=$1
echo "Converting package ${pkg_name}" 

deb_pkg_info=$(apt-cache show ${pkg_name}:amd64)
deb_pkg_arch=$(echo "$deb_pkg_info" | grep -m 1 "Architecture:" | sed "s/Architecture: //")
deb_pkg_version=$(echo "$deb_pkg_info" | grep -m 1 "Version:" | sed "s/Version: //")

echo "Debian Arch: ${deb_pkg_arch}"
echo "Debian Version: ${deb_pkg_version}"

if [ "${deb_pkg_arch}" != "amd64" ]; then
    echo "Package has not AMD64 architecture. Skipping it."
    exit 2
fi

rasp_pkg_info=$(apt-cache show ${pkg_name}:armhf)
rasp_pkg_version=$(echo "$rasp_pkg_info" | grep "Version:" | sed "s/Version: //")

echo "Raspbian Version: ${rasp_pkg_version}"

call_dir=$PWD
tmp_dir="./pkg_tmp"

echo "Creating tempory directory: ${tmp_dir}"
rm -rf ${tmp_dir}
mkdir -p ${tmp_dir} || exit 1
cd ${tmp_dir} || exit 1

echo "Downloading debian version of package"
apt-get download ${pkg_name}:amd64

echo "Unpacking control file from  package "
ar xf *.deb
mkdir ctrl
cd ctrl
tar xf ../control.*
echo "Changing version in control file to: ${rasp_pkg_version}"
sed -i "s/Version: .*/Version: ${rasp_pkg_version}/" control

echo "Packing control file into control.*"
tar caf ../control.* .
cd ..

deb_fn="${pkg_name}_${rasp_pkg_version}_amd64.deb"
echo "Packing debian package: ${deb_fn}"
ar r "${call_dir}/${deb_fn}" debian-binary control.tar.* data.tar.* || exit 1

echo "Removing tmp dir"
cd ${call_dir}
rm -r ${tmp_dir}

echo "Done"

echo "Comparing base versions"

rasp_pkg_version_base=${rasp_pkg_version%+*}

echo "Debian: ${deb_pkg_version}"
echo "Raspbian: ${rasp_pkg_version_base}"

if [ "${rasp_pkg_version_base}" != "${deb_pkg_version}" ]; then
   echo "Packages have version conflicts."
   exit 3
else
   echo "Base versions matching"
   exit 0
fi

