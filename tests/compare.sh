#!/bin/bash

list=$1

[ -z "$list" ] && echo "Need argument" && exit 1

rm -f $list.ratio_time $list.ratio_feval $list.good
echo "y_nm = [" > nm_profile.m
echo "y_ds = [" > ds_profile.m
echo "x = [1.0" > x_profile.m

for problem in $(cat $list)
do
  nm_objvalue=$(awk '/Objective value/ {print $4}' neldermead_out/$problem.out)
  nm_setuptime=$(awk '/Setup time/ {print $3}' neldermead_out/$problem.out)
  nm_solvetime=$(awk '/Solve time/ {print $3}' neldermead_out/$problem.out)
  nm_feval=$(awk '/Number of/ {print $6}' neldermead_out/$problem.out)
  ds_objvalue=$(awk '/Objective value/ {print $4}' directsearch_out/$problem.out)
  ds_setuptime=$(awk '/Setup time/ {print $3}' directsearch_out/$problem.out)
  ds_solvetime=$(awk '/Solve time/ {print $3}' directsearch_out/$problem.out)
  ds_feval=$(awk '/Number of/ {print $6}' directsearch_out/$problem.out)

  if [ -z "$nm_objvalue" -a -z "$ds_objvalue" ]; then
    #echo "$problem MAX MAX" >> $list.ratio_time
    #echo "$problem MAX MAX" >> $list.ratio_feval
    echo "inf" >> nm_profile.m
    echo "inf" >> ds_profile.m
  elif [ -z "$nm_objvalue" ]; then
    echo "$problem" >> $list.good
    echo "$problem MAX 1.0" >> $list.ratio_time
    echo "$problem MAX 1.0" >> $list.ratio_feval
    echo "inf" >> nm_profile.m
    echo "1.0" >> ds_profile.m
  elif [ -z "$ds_objvalue" ]; then
    echo "$problem" >> $list.good
    echo "$problem 1.0 MAX" >> $list.ratio_time
    echo "$problem 1.0 MAX" >> $list.ratio_feval
    echo "1.0" >> nm_profile.m
    echo "inf" >> ds_profile.m
  else
    echo "$problem" >> $list.good
    nm_time=$(echo "scale=5; $nm_setuptime+$nm_solvetime" | bc)
    ds_time=$(echo "scale=5; $ds_setuptime+$ds_solvetime" | bc)
    ratio=$(octave -q --eval "M=min($nm_time,$ds_time); disp([$nm_time/M, $ds_time/M])")
    echo "$problem $ratio" >> $list.ratio_time

    ratio=$(octave -q --eval "M=min($nm_feval,$ds_feval); disp([$nm_feval/M, $ds_feval/M])")
    echo "$problem $ratio" >> $list.ratio_feval

    echo $(octave -q --eval "M=min($nm_feval,$ds_feval); disp($nm_feval/M)") >> nm_profile.m
    echo $(octave -q --eval "M=min($nm_feval,$ds_feval); disp($ds_feval/M)") >> ds_profile.m
    echo $(octave -q --eval "M=min($nm_feval,$ds_feval); disp(max($nm_feval/M,$ds_feval/M))") >> x_profile.m
  fi
done

echo "];" >> nm_profile.m
echo "];" >> ds_profile.m
echo "];" >> x_profile.m

sed -i 's/MAX/1e10/g' $list.ratio_time
sed -i 's/MAX/1e10/g' $list.ratio_feval

echo "nm_profile" > perf_prof.m
echo "ds_profile" >> perf_prof.m
echo "x_profile" >> perf_prof.m
echo "x = unique(sort(x));" >> perf_prof.m
echo "nm = sum(y_nm <= x');" >> perf_prof.m
echo "ds = sum(y_ds <= x');" >> perf_prof.m
echo "M = max([nm,ds]); nm = nm/M; ds = ds/M;" >> perf_prof.m

echo "h = plot(x,nm,'r',x,ds,'b');" >> perf_prof.m
echo "axis([1,max(x),0,1])" >> perf_prof.m
echo "set(gca,'YTick',0:0.2:1)" >> perf_prof.m
echo "set(h,'linewidth',3)" >> perf_prof.m
echo "legend('nelder-mead','direct search','location','southeast')" >> perf_prof.m
echo "legend('boxon')" >> perf_prof.m
echo "print('profile.png')" >> perf_prof.m

echo "h = semilogx(x,nm,'r',x,ds,'b');" >> perf_prof.m
echo "axis([1,max(x),0,1])" >> perf_prof.m
echo "set(gca,'YTick',0:0.2:1)" >> perf_prof.m
echo "set(h,'linewidth',3)" >> perf_prof.m
echo "legend('nelder-mead','direct search','location','southeast')" >> perf_prof.m
echo "legend('boxon')" >> perf_prof.m
echo "print('profile_log.png')" >> perf_prof.m

octave --eval 'perf_prof'
