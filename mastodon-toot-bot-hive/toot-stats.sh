#!/usr/bin/env bash
# A string with command options
# example usage: get last week of data and don't toot about it , exclude nonpodping, do push to git hub:
# -daily- 
# ./toot-stats.sh -H 168 -n true -t false -p true
# -weekly-
# ./toot-stats.sh -H 168 -n true -t false -p true
# -monthly- Every 29.8 days resolves to 30 day file names
# ./toot-stats.sh -H 717 -n true -t false -p true
# This method for arguments is simple to use,
# but less flexible (not smart), can't use -nt, use:

# Set defaults
############################3
# -t argument
tootSummary=false
# -n argument
excludeNonPodping=false
# -push results to github
pushToGit=false
# https://stackoverflow.com/a/6946864

options=$@
# An array with all the arguments
arguments=($options)
# Loop index
index=0
for argument in $options
  do
    index=`expr $index + 1`
    # The conditions
    case $argument in
      -H) historyHours=${arguments[index]} ;;
      -n) excludeNonPodping=${arguments[index]} ;;
      -t) tootSummary=${arguments[index]} ;;
      -p) pushToGit=${arguments[index]} ;;
    esac
  done

# attempt to get the current script's path on disk
TMP_PATH=`dirname "$0"`
SCRIPT_PATH=`( cd "$TMP_PATH" && pwd )`
# [TODO] add test for expected files, report to error log
# bash testing: https://ss64.com/bash/test.html

# Set current working directory for the rest of the script
cd $SCRIPT_PATH
# remove the data csv files (start fresh)
rm $SCRIPT_PATH/data*
# run the python tool to query for the past 24 hours
# this takes roughly 5 minutes per day's worth of information, each day is .3 gb
echo $historyHours
if $excludeNonPodping; then
  $SCRIPT_PATH/hive-watcher.py --include-unauthorized --write-csv --history-only --old $historyHours
else
  $SCRIPT_PATH/hive-watcher.py --include-unauthorized --include-nonpodping --write-csv --history-only --old $historyHours
fi

# cleanup the lastSummary.txt file ([TODO] move this to the R script...)
rm $SCRIPT_PATH/stats/lastSummary.txt

# run the rscript to generate analytics
$SCRIPT_PATH/visualize-data.R

if $pushToGit; then
  # Push changes to github pages
  git add $SCRIPT_PATH/../. && git commit -m "update reports" && git push
  if $tootSummary ; then
    # wait for 15 seconds to allow for the git hub pages to be updated
    # prior to tooting
    sleep 15s
  fi
else
  echo "Not pushing reports to github"
fi

if $tootSummary; then
  # toot the stats
  $SCRIPT_PATH/toot-last-summary-stats.py
fi
