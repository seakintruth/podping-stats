#!/usr/bin/env python3
import requests
# read in credentials - url
file = open("credentials/mastodon_site_url.txt")
mastodon_site_url = file.read().rstrip()
file.close()
# read in credentials - token
file = open("credentials/token.txt")
access_token = file.read().rstrip()
file.close()
# read summary stats to string
file = open("stats/lastSummary.txt")
summary_stats = file.read().rstrip()
file.close()

# build the curl request
url = mastodon_site_url + '/api/v1/statuses'
auth = {'Authorization': 'Bearer '+ access_token}
params = {'status': summary_stats }

# publish
print("Posting to " + mastodon_site_url)

r = requests.post(url, data=params, headers=auth)
print(r)

#[TODO]
# if not str(r)=="<Response [200]>" 
#    THROW AN ERROR to logs/errors-toot-last-summary-stats.
