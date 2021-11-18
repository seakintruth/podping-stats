#!/usr/bin/env sh
# set log path
LogPath=/data/logs/crontab/shiny_sync.txt
echo "---------------------------------" >> $LogPath
date -u >> $LogPath
echo "---------------------------------" >> $LogPath
echo "start Rsync from shiny server to git repo location" >>  $LogPath

sudo rsync -avzL --delete /var/www/podping-stats_com/ /data/git/podping-stats/web-dashboards/
sudo chown jeremy_gerdes:jeremy_gerdes -R /data/git/podping-stats/web-dashboards/
sudo find /data/git/podping-stats -type d -exec chmod 755 {} \;
sudo find /data/git/podping-stats -type f -exec chmod 777 {} \;
