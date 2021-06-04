# Stats Reports
[Stats for mastodon-toot-bot-hive](https://seakintruth.github.io/podping-stats/mastodon-toot-bot-hive/stats/)

# I'm a bot
... in training ...

This bot posts summary statistics about podping on hive.io to a mastodon instance ... data exploration in [R](https://cran.r-project.org/) of the [podping](podping.cloud) data being reported on the [hive.io](hive.io) blockchain. 

Currently running seperate reports and toots via this `crontab -e`
```
# At minute 30 past every 2nd hour, generate weekly charts, don't toot
30 */2 * * * ~/git/podping-stats/mastodon-toot-bot-hive/toot-stats.sh -H 168 -n true -t false -p true >> ~/git/podping-stats/mastodon-toot-bot-hive/logs/crontab.log

# at minute 0 every hour,  generate last daily report, don't toot
0 * * * * ~/git/podping-stats/mastodon-toot-bot-hive/toot-stats.sh -H 24 -n true -t false -p true >> ~/git/podping-stats/mastodon-toot-bot-hive/logs/crontab.log

# at minute 15 on hour 7 every day - Toot the message with non-podping info at 7:15 am
15 7 * * * ~/data_monthly_podping-stats/mastodon-toot-bot-hive/toot-stats.sh -H 24 -n false -t true -p true >> ~/git/podping-stats/mastodon-toot-bot-hive/logs/crontab.log

# Seperate folder for this data, as it takes a while and don't want to interfer with the other data sets...
# at minute 30 on hour 11 every Sunday begin - Toot the monthly data message with non-podping info
1 11 * * 1 rm ~/data_monthly_podping-stats/mastodon-toot-bot-hive/stats/* && ~/data_monthly_podping-stats/mastodon-toot-bot-hive/toot-stats.sh -H 717 -n false -t true -p false && cp ~/data_monthly_podping-stats/mastodon-toot-bot-hive/stats/* ~/git/podping-stats/mastodon-toot-bot-hive/stats/ && git -C ~/git/podping-stats commit -a -m "update reports" && git -C ~/git/podping-stats push >> ~/git/podping-stats/mastodon-toot-bot-hive/logs/crontab.log

```

The most granular report currently availble with these scripts is one hour - don't want to spam the mastodon instance, so sticking with daily for now...

# Dependancies
- Linux (install depenencies examples here are for apt (debian based distros)
- Ensure python3 and pip are installed (check with `pip --version`)
- Install beem wit pip
```
pip3 install beem
```
- Install R
```
sudo apt install r-base r-base-core r-recommended
```
# Running the scripts
## Everything is a script
Some automation - make these scripts executable
- navigate to this folder and run:
```
sudo chmod +x *.py *.R *.sh
```
## Start the python script
Then to begin or resume collecting data run and toot:
```
./hive-watcher-write-to-csv.py
```

## Visualize it
After running for awhile run the data visualization script with:
```
./visualize-data.R 
```

## Results
What's the delay between the watcher and the posted time stamp on the hive blockchain?
Here is a histogram for that.
![Example Histogram](stats/image-timestamp_delay_hist.png)

And for all other 'custom json' posts on hive for the same period
![Example Histogram](stats/image-timestamp_delay_hist-non-podping.png)

And others. 

The last thing the [visualize-data.R](visualize-data.R) script does is write as a log the following to a [.ndjson file](stats/summaryStats.ndjson):

```
Podping hive "custom json" post summary:
    Post count is 2710 (2.95 posts/min)
    Total urls posted is 12128 of wich 6258 are unique
        (average of 4.48 urls/post)
    All 'other' hive post count is 458672 (500 posts/min)
    Podping portion of all 'custom json' posts on hive is 0.58737%
    From 2021-05-20 03:46:36 UTC to 2021-05-20 19:03:56 UTC
    Watched for 15 hours 17 minutes and 20.15 seconds
#podping #Stats
```

# This Project is based on this example:
- On github -> [podping.cloud](https://github.com/Podcastindex-org/podping.cloud/tree/main/hive-watcher/examples/write-to-csv-analyze-with-R)
