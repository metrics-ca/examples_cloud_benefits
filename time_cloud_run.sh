#!/usr/bin/env bash

if [ "$#" -eq 0 ]; then
  echo "Please pass in the Job ID as an argument"
  exit 1
fi

jobID=$1

start_time=`date '+%s'`
 
mdc job status ${jobID} -w

end_time=`date '+%s'`
secs=$((end_time-start_time))
echo "Execution time was ${secs} seconds."
date

