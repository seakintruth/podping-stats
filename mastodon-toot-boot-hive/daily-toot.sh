#!/usr/bin/env bash
# remove the data csv files (start fresh)
rm data*
# run the python tool to query for the past 24 hours
./hive-watcher.py --include-unauthorized --include-nonpodping --write-csv --history-only --old 24
# run the rscript to generate analytics
./visualize-data.R
