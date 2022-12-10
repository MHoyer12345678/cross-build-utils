#!/bin/bash

# convert-pkg-deps-line.sh <pkg_name>
# return code: 0: everything fine, 1: error 

# - unpack packages control file
# - iterate through "Depends: " line dependency by dependency
# - Create new dependency line
#     * if no = is in, take over ", <dependency>"
#     * in case of =:
#         + extract version from package fn of dependend package (needs to be available in folder)
#         + add dependency ", pkg_name ( = <dependency>)"
# - replace old w/ new line in control file
# - repack package

if [ $# -eq 0 ]; then
    echo "Name of package to convert missing"
    exit 1
fi

pkg_name=$1
echo "Adapting dependencies in package ${pkg_name}" 

rasp_pkg_fn=$(ls ${pkg_name}_*)
echo "Raspbian pkg fFilename: ${rasp_pkg_fn}" 

call_dir=$PWD
tmp_dir="./pkg_tmp"

echo "Creating tempory directory: ${tmp_dir}"
rm -rf ${tmp_dir}
mkdir -p ${tmp_dir} || exit 1
cd ${tmp_dir} || exit 1

echo "Unpacking control file from  package "
ar xf "${call_dir}/${rasp_pkg_fn}"
mkdir ctrl
cd ctrl
tar xf ../control.*

dep_line=$(grep "^Depends: " ./control | sed "s/Depends: //")
echo "Depends line: ${dep_line}"

new_dep_line="Depends: "
is_first=1

IFS=,
for dep_entry in ${dep_line}
do
    dep_pkg="${dep_entry%%(*}"
    dep_pkg="${dep_pkg// /}"

    echo "${dep_entry}" | grep "(\s*=\s*" > /dev/null

    if [ $? -ne 0 ]; then
	echo "Dependency entry ${dep_entry} does not refer to an exakt version. Taking it over directly" 
	to_add="${dep_entry}"
    else
	echo "Dependency entry ${dep_entry} refers to an exakt version. Replacing it by raspbian version of the package." 
	echo "Getting raspbian version of: $dep_pkg"
	dep_rasp_pkg_fn=$(ls ${call_dir}/${dep_pkg}_*)
	rasp_pkg_version=${dep_rasp_pkg_fn#*_}
	rasp_pkg_version=${rasp_pkg_version%_*}
	echo "Version of raspbian package is: $rasp_pkg_version"
	to_add="${dep_pkg} (= ${rasp_pkg_version})"
    fi

    if [ $is_first -eq 1 ]; then
       new_dep_line="${new_dep_line}${to_add}"
       is_first=0
    else
	new_dep_line="${new_dep_line}, ${to_add}"
    fi	   
done

echo "Replacing depends line in control file with: ${new_dep_line}"
sed -i "s/Depends: .*/${new_dep_line}/" ./control

echo "Packing control file into control.*"
tar caf ../control.* .
cd ..

echo "Packing package again: ${rasp_pkg_fn}"
ar r "${call_dir}/${rasp_pkg_fn}" debian-binary control.tar.* data.tar.* || exit 1

echo "Removing tmp dir"
cd ${call_dir}
rm -r ${tmp_dir}

echo "Done"

