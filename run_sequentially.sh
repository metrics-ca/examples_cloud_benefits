#!/usr/bin/env bash

if [ -f dsim_work ]; then
  rm -rf dsim_work
fi
 
start_time=`date '+%s'`
 
dlib map -lib ieee ${STD_LIBS}/ieee08
 
dvhcom +acc+b -vhdl2008 -lib work -f filelist.txt

dvlcom +acc+b +incdir+./source/+./sv/ dbg_link/sv_sim/sv/*.sv

dsim +acc+b -lib work -top work.tb_top -genimage image
 
end_time=`date '+%s'`
secs=$((end_time-start_time))
echo "Build time was ${secs} seconds."
 
start_time=`date '+%s'`

for i in {0..31};
do
    dsim -image image -sv_seed $i -l logs/dsim$i.log
    echo ""
    echo ""
done
 
end_time=`date '+%s'`
secs=$((end_time-start_time))
echo "Execution time was ${secs} seconds."
date
