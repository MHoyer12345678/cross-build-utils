#!/bin/bash

# ---------------- create package list -------------------------------------
# - create list w/ dpkg -l > textfile
# - extract packages column
# - remove :amd64
# - remove essential libs and rasp gcc from list

