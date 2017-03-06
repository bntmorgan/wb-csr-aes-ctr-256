#!/bin/bash

cat > $1 << EOF 
setMode -bscan
setCable -port auto
identify -inferir
identifyMPM
assignFile -p 2 -file $2
program -p 2
closeCable
quit 
EOF
