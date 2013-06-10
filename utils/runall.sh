#! /bin/sh

for f in `find configs/*.coffee`; do
  ./benchmark.coffee $f > `echo $f | sed -e 's/^configs\/\(.*\)\.coffee/results\/\1\.json/'`;
  ./table.coffee `echo $f | sed -e 's/^configs\/\(.*\)\.coffee/results\/\1\.json/'` --latex > `echo $f | sed -e 's/^configs\/\(.*\)\.coffee/tex\/\1\.tex/'`
done