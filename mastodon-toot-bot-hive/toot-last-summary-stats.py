#!/usr/bin/env python3
import requests
# read in last summary_stats  from ./stats/summaryStats.ndjson
file = open("credentials/mastodon_site_url.txt")
mastodon_site_url = file.read()
file.close()
# read in credentials
file = open("credentials/token.txt")
access_token = file.read()
file.close()
# read summary stats to string
file = open("stats/lastSummary.txt")
summary_stats = file.read()
file.close()

# build the curl request
url = mastodon_site_url + '/api/v1/statuses'
auth = {'Authorization': 'Bearer '+ access_token}
params = {'status': summary_stats }

# publish
print("Posting to " + mastodon_site_url)
r = requests.post(url, data=params, headers=auth)
print(r)
