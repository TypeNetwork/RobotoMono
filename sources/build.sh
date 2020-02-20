#!/bin/sh
set -e

# Go the sources directory to run commands
SOURCE="${BASH_SOURCE[0]}"
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd $DIR
echo $(pwd)

echo "Generating Static fonts"
mkdir -p ../fonts
fontmake --keep-overlaps -m RobotoMono.designspace -i -o ttf --output-dir ../fonts/ttf/

echo "Generating VFs"
mkdir -p ../fonts/vf
fontmake -m RobotoMono.designspace -o variable --output-path ../fonts/vf/RobotoMono[wght].ttf

rm -rf master_ufo/ instance_ufo/ instance_ufos/ instances/


echo "Post processing"
ttfs=$(ls ../fonts/ttf/*.ttf)
for ttf in $ttfs
do
	gftools fix-dsig -f $ttf;
	echo "TTF AH"
	python3 -m ttfautohint --stem-width-mode nnn $ttf "$ttf.fix";
	mv "$ttf.fix" $ttf;
done

vfs=$(ls ../fonts/vf/*\[wght\].ttf)

echo "Post processing VFs"
for vf in $vfs
do
	gftools fix-dsig -f $vf;
done


echo "Fixing VF monospace metadata"
for vf in $vfs
do
	gftools fix-isfixedpitch --fonts $vf;
	mv "$vf.fix" $vf;
done

echo "Fixing VF Meta"
gftools fix-vf-meta $vfs;

echo "Dropping MVAR"
for vf in $vfs
do
	mv "$vf.fix" $vf;
	ttx -f -x "MVAR" $vf; # Drop MVAR. Table has issue in DW
	rtrip=$(basename -s .ttf $vf)
	new_file=../fonts/vf/$rtrip.ttx;
	rm $vf;
	ttx $new_file
	rm $new_file
done

echo "Fixing Hinting"
for vf in $vfs
do
	gftools fix-nonhinting $vf $vf.fix;
	mv "$vf.fix" $vf;
done

rm  ../fonts/vf/*gasp.ttf

