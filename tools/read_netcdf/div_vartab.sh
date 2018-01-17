#!/bin/bash
while read -r l; do a=$(echo $l | cut -d' ' -f1);echo $l>dimensions_$a; done <variables.tabular
for f in dimensions_*; do cat $f | sed 's/ /\t\n/g' | sed '$s/$/ /' >$f.tabular; done
for f in dimensions_*.tabular;do cat $f | awk 'NR % 2 != 0' $f > $f.2
sed 1d $f.2 > $f
rm $f.2;done
