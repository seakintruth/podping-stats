#!/usr/bin/env bash
# bash argument hanling: https://stackoverflow.com/a/18414407
while getopts H: flag
do
    case "${flag}" in
        H) historyHours=${OPTARG};;
    esac
done

# [TODO] add test for expected files, report to error log
# bash testing: https://ss64.com/bash/test.html

# remove the data csv files (start fresh)
rm data*
# run the python tool to query for the past 24 hours
# this takes roughly 5 minutes per day's worth of information, each day is .3 gb
./hive-watcher.py --include-unauthorized --include-nonpodping --write-csv --history-only --old $historyHours

# cleanup the lastSummary.txt file
rm ./stats/lastSummary.txt

# run the rscript to generate analytics
./visualize-data.R

# Toot with our bot
./toot-last-summary-stats.py
