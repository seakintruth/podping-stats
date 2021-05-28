#!/usr/bin/env bash
# A string with command options
# example usage: get last week of data and don't toot about it , exclude nonpodping:
# ./toot-stats.sh -H 168 -n true -t true
# -t argument
testRun=false
# -n argument
excludeNonPodping=false
# https://stackoverflow.com/a/6946864
# This method is simple to use, but less flexible (not smart), can't use -nt, use:
# ~/git/podping-stats/mastodon-toot-bot-hive/toot-stats.sh -H 720 -n true -t true

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
      -t) testRun=${arguments[index]} ;;
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

# cleanup the lastSummary.txt file
rm $SCRIPT_PATH/stats/lastSummary.txt

# run the rscript to generate analytics
$SCRIPT_PATH/visualize-data.R

if $testRun; then
  echo "Not tooting durring testing"
else
  # toot the stats
  $SCRIPT_PATH/toot-last-summary-stats.py
fi

git add . && git commit -m "update reports" && git push