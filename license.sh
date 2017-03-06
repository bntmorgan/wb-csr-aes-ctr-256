#!/bin/bash
# script to copy the headers to all the source files and header files
for f in `find . -type f | grep -i "\.\(c\|h\|v\)$"`; do
  if (grep Copyright $f);then 
    echo "No need to copy the License Header to $f"
  else
		echo "/*" > $f.new
    cat LICENSE >> $f.new
		echo "*/" >> $f.new
		echo "" >> $f.new
		cat $f >> $f.new
    mv $f.new $f
    echo "License Header copied to $f"
  fi 
done 
