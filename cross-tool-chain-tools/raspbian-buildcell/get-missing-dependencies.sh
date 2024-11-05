#!/bin/bash

# get-missing-dependencies.sh <pkg_name>
# return code: 0: everything fine, 1: error 

# - recusively:
#    * check package
#        * skip if already present as package in directory
#        * skip if already part of dependencies-to-add list
#        * else:
#             + add to dependencies-to-add list
#             + Get package depedends line using apt-cache show pkgname (amd64 version)
#             + check each entry in "Depends: " line the same way
#    * print out dependencies-to-add list

if [ $# -eq 0 ]; then
    echo "Name of package to convert missing"
    exit 1
fi

open_dep_list=""

function check_deps()
{
    pkg_name=$1

    #check if in dir
    echo -n "Checking if package ${pkg_name} is available as deb file in current directory ..."
    ls ${pkg_name}*.deb &> /dev/null
    if [ $? -eq 0 ]; then
	echo " Found. Not adding it to the list."
	return
    fi
    echo "It is not!"

    #check if in list
    echo -n "Checking if package ${pkg_name} is already in dependencies-to-add list ..."
    echo "$open_dep_list" | grep ${pkg_name} &> /dev/null
    if [ $? -eq 0 ]; then
	echo " Found. Not adding it to the list."
	return
    fi
    echo "It is not!"

    echo "Adding ${pkg_name} to list and checking for its dependencies"
    open_dep_list="${open_dep_list} ${pkg_name}"

    echo "Checking dependencies in package ${pkg_name}"

    pkg_info=$(apt-cache show ${pkg_name}:amd64)
    
    dep_line=$(echo "${pkg_info}" | grep -m 1 "^Depends: " | sed "s/Depends: //")
    echo "Depends line: ${dep_line}"
    
    IFS=,
    for dep_entry in ${dep_line}
    do
	dep_pkg="${dep_entry%%(*}"
	dep_pkg="${dep_pkg%%:*}"
	dep_pkg="${dep_pkg// /}"

	check_deps ${dep_pkg}
    done

    dep_line=$(echo ${pkg_info} | grep -m 1 "^Pre-Depends: " | sed "s/Pre-Depends: //")
    echo "Depends line: ${dep_line}"
    
    for dep_entry in ${dep_line}
    do
	dep_pkg="${dep_entry%%(*}"
	dep_pkg="${dep_pkg// /}"

	check_deps ${dep_pkg}
    done
}

check_deps $1

echo "List to add: ${open_dep_list}"
