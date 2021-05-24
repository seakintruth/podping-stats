#!/usr/bin/env bash
# A string with command options
testRun=false
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
      -t) testRun=${arguments[index]} ;;
    esac
  done

# attempt to get the current script's path on disk
TMP_PATH=`dirname "$0"`
SCRIPT_PATH=`( cd "$TMP_PATH" && pwd )`
# [TODO] add test for expected files, report to error log
# bash testing: https://ss64.com/bash/test.html

# remove the data csv files (start fresh)
rm $SCRIPT_PATH/data*
# run the python tool to query for the past 24 hours
# this takes roughly 5 minutes per day's worth of information, each day is .3 gb
echo $historyHours
$SCRIPT_PATH/hive-watcher.py --include-unauthorized --include-nonpodping --write-csv --history-only --old $historyHours

# cleanup the lastSummary.txt file
rm $SCRIPT_PATH/stats/lastSummary.txt

# run the rscript to generate analytics
$SCRIPT_PATH/visualize-data.R

if ! $testRun; then 
    # toot the stats
    $SCRIPT_PATH/toot-last-summary-stats.py
else
    echo "Not tooting to mastodon while testing"
fi