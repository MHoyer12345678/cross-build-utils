#!/bin/bash

# ---------------- create package list -------------------------------------
# - create list w/ dpkg -l > textfile
# - extract packages column
# - remove :amd64
# - remove essential libs and rasp gcc from list

if [ $# -eq 0 ]; then
    echo "Missing file with list of packages."
    exit 1
fi

pkg_list_success=""
pkg_list_version_conflict=""
pkg_list_no_amd64=""
pkg_list_skipped_present=""
pkg_list_need_deps_rework=""

pkg_list_fn=$1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

while IFS= read -r pkg
do
    echo "Converting pkg: $pkg"

    echo "Checking if package has already bin converted ..."
    ls ${pkg}* &> /dev/null
    if [ $? -eq 0 ]; then
	echo "Package already converted. Skipping it."
	pkg_list_skipped_present="${pkg_list_skipped_present}${pkg} "
	continue
    fi
    echo "Package not found. Start converting it"
    
    $SCRIPT_DIR/convert-pkg-deb-rasp.sh ${pkg}
    ret=$?
    case $ret in
	0 | 4)
	    pkg_list_success="${pkg_list_success}${pkg} "
	    ;;

	2 | 6)
	    pkg_list_no_amd64="${pkg_list_no_amd64}${pkg} "
	    ;;

	3 | 7)
	    pkg_list_version_conflict="${pkg_list_version_conflict}${pkg} "
	    ;;

	*)
	    echo "Unrecoverable error. Exiting ..."
	    exit 1
	    ;;
    esac

    if [ $ret -eq 4 ] || [ $ret -eq 6 ] || [ $ret -eq 7 ]; then
	pkg_list_need_deps_rework="${pkg_list_need_deps_rework}${pkg} "
    fi
    

done < "$pkg_list_fn"

echo "Following packages need rework of dependencies: ${pkg_list_need_deps_rework}"


echo "---------------------------- Done -------------------------------------"
echo "List of successfully ported packages: ${pkg_list_success}"
echo ""
echo "Packages not AMD64 (just downloaded from raspbian): ${pkg_list_no_amd64}"
echo ""
echo "Packages skipped because already converted before: ${pkg_list_skipped_present}"
echo ""
echo "Packages with version conflicts: ${pkg_list_version_conflict}"
echo ""
