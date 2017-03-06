#!/bin/bash

# $1 : outfile
# $2 : top module
# $3 : board package
# $4 : prj file
# $5 : ngc file
# $6 : free string

cat > $1 << EOF 
run
-ifn $4
-top $2
-ifmt MIXED
-opt_mode AREA
-opt_level 2
-resource_sharing YES
-reduce_control_sets AUTO
-p $3
-ofn $5
$6
EOF
