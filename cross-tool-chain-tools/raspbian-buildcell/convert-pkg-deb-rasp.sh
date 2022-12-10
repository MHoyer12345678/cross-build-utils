#!/bin/bash

# convert-pkg-deb-rasp.sh <pkg_name>
# return code: 0,4: verything fine, 1: error, 2,6: no AMD64 package -> downloaded directly from raspbian, 3,7: version conflict detected, package processed anyway, 4,6,7: need dep rework in package 

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
deb_pkg_deps=$(echo "$deb_pkg_info" | grep -m 1 "^Depends:" | sed "s/Depends: //")


echo "Debian Arch: ${deb_pkg_arch}"
echo "Debian Version: ${deb_pkg_version}"
echo "Debian Depends: ${deb_pkg_deps}"

need_rework_ret_code=0

if [ "${deb_pkg_deps}" != "" ]; then

    echo "Checking for dependencies with exact versions required (= <version>)."  
    # check if there are deps requiring exact version (= <version>)
    echo "${deb_pkg_deps}" | grep "(\s*=\s*"

    if [ $? -eq 0 ]; then
	echo "Package contains exact dependencies. Need rework of dependency line."
	need_rework_ret_code=4
    else
	echo "Package does not contain dependencies with exact version required."
    fi
fi

if [ "${deb_pkg_arch}" != "amd64" ]; then
    echo "Package has not AMD64 architecture. Downloading the raspberry version."
    apt-get download ${pkg_name}:all
    exit $((need_rework_ret_code+2))
fi

rasp_pkg_info=$(apt-cache show ${pkg_name}:armhf)
if [ $? -ne 0 ]; then
    echo "Package has no candidate in raspbian. Just downloading the package w/o converting it."
    apt-get download ${pkg_name}
    exit $((need_rework_ret_code+0))
fi
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

deb_pkg_version_base=${deb_pkg_version%%+*}
rasp_pkg_version_base=${rasp_pkg_version%%+*}

echo "Debian(base): ${deb_pkg_version_base}"
echo "Raspbian(base): ${rasp_pkg_version_base}"

if [ "${rasp_pkg_version_base}" != "${deb_pkg_version_base}" ]; then
   echo "Packages have version conflicts."
   exit $((need_rework_ret_code+3))
else
   echo "Base versions matching"
   exit $((need_rework_ret_code+0))
fi

