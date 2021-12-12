#!/bin/bash

rm eval1.txt 2> /dev/null
rm eval2.txt 2> /dev/null

saveName=${1:-"results"}

FILES="."/*

for f in $FILES
do
	f=$(basename $f)
	if [[ $f =~ \.mat$ ]]; then
		name=${f%m.mat*}
		wrann -r $name -a det < $name".asc"
		bxb -r $name -a atr det -l eval1.txt eval2.txt
	fi
done

sumstats eval1.txt eval2.txt > $saveName.txt
