#!/bin/bash

list=$1

[ -z "$list" ] && echo "Argument expected" && exit 1
[ ! -f $list ] && echo "$list is not a file/does not exists" && exit 1

algs="neldermead directsearch"

for i in $algs
do
  mkdir -p ${i}_out
done

for problem in $(cat $list)
do
  for i in $algs
  do
    timeout 10 runcppcuter -p $i -D $problem > ${i}_out/$problem.out
  done
done
