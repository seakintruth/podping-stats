# Dependancies:
# This script was developed on linux/ubuntu and depends on having previously installed these packages: 
# sudo apt install libssl-dev openssl curl libcurl4-openssl-dev 
# Example:
# payload <- podcast_index_get_feed_by_url("https://www.podserve.fm/series/rss/2577/playbyplay.rss")
# https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html
# for more information, see https://api.podcastindex.org/developer_docs

library(httr)
library(jsonlite)
library(digest)

.set_podcast_env <- function() {
  if (Sys.getenv("podcastIndexKey") == ""){
    conn <- file("~/env/podcastIndexKey.txt")
    Sys.setenv(podcastIndexKey = readLines(conn)[1])
    close(conn)
  }
  if (Sys.getenv("podcastIndexSecret") == ""){
    conn <- file("~/env/podcastIndexSecret.txt")
    Sys.setenv(podcastIndexSecret = readLines(conn)[1])
    close(conn)
  }
}

# defaults to returning trending english podcast feeds for the past day...
.podcast_index_api_call_get <- function(      
  url = "https://api.podcastindex.org", 
  path = "/api/1.0/podcasts/trending",
  query = "max=7&since=-86400&lang=en"
){
  # Set key and secret
  .set_podcast_env()
  api_key <- Sys.getenv("podcastIndexKey")
  api_secret <-  Sys.getenv("podcastIndexSecret")
    # the api follows the Amazon style authentication
    # see https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_Authentication2.html
    # podcast_index <- handle("https://api.podcastindex.org")
    user_agent <- paste0(
      R.version.string,
      " (",
      paste(
        Sys.info()[c("machine","sysname","release")],
        sep = "",
        collapse = " "
      ),"; script; shiny-app;)"
    )	
    # For fun: Sets User-Agent to something like (that date is the R version date):
    # R version 4.0.5 (2021-03-31) (x86_64 Linux 5.8.0-48-generic; script; podcasting-index-r-cli)
    
    # we'll need the unix time, for a linux system just using: 
    epoch_time <- as.numeric(as.POSIXlt(Sys.time(), "GMT"))
    
    # our hash here is the api key + secret + time 
    data_to_hash <- paste0(
      api_key, api_secret, as.character(epoch_time)
    )
    # which then generates the authorization hash via sha-1 (had to set serialize=FALSE, to work)
    sha_1 <- digest::digest(data_to_hash,algo="sha1",serialize=FALSE)
    
    # GET our payload
    response <- GET(
      url = url, 
      path = path,
      query = query,
      add_headers(
        `User-Agent` = user_agent,
        `X-Auth-Date` = epoch_time,
        `X-Auth-Key` = api_key,
        Authorization = sha_1,
        Accept = "application/json"
      )
    )
    
    # Comment this line out for production, displays results
    # message(jsonlite::prettify(httr::content(response, "text",indent=4)))
    parsed <- jsonlite::fromJSON(httr::content(response, "text"), simplifyVector = FALSE)
    return(parsed)
}

podcast_index_get_by_url <- function(feedUrl){
  podcast_index_get_feed_by_url(feedUrl)
}

# The search for feed by url function
podcast_index_get_feed_by_url <- function(feedUrl){
  .podcast_index_api_call_get(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/byfeedurl",
      query = paste0("url=",feedUrl)
    )
}
# The search for feed by url function
podcast_index_get_feed_by_guid <- function(guid){
  .podcast_index_api_call_get(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/byguid",
      query = paste0("guid=",guid)
    )
}

# The search for feed by feed ID
podcast_index_get_feed_by_feedId <- function(feedId){
  .podcast_index_api_call_get(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/byfeedid",
      query = paste0("id=",feedId)
    )
}

# The search for feed by iTunes ID
podcast_index_get_feed_by_itunesid <- function(itunesId){
  .podcast_index_api_call_get(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/byitunesid",
      query = paste0("id=",itunesId)
    )
}

# The search for feed by podcast namespace tag
podcast_index_get_feed_by_tag <- function(tag){
  .podcast_index_api_call_get(
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/bytag",
      query = tag
    )
}

# The search for feed by podcast namespace tag
# defaults are return 10 feeds trending in the past day.
podcast_index_get_feed_trending <- function(
  max = 10,
  since=-86400,
  languageR="en",
  cat="",
  notcat=""
){
  if (max>1000) {
    message(
      "WARNING:podcast_index_get_feed_trending parameter max exceeded 1000, reset value to 1000"
    )
    max <- 1000
  } else if (max<1) {
    message(
      "WARNING:podcast_index_get_feed_trending parameter max exceeded minimum of 1, reset value to 1"
    )
    max <- 1
  }

  .podcast_index_api_call_get(
    url = "https://api.podcastindex.org", 
    path = "/api/1.0/podcasts/trending",
    query = paste0(
      "max=",max,
      "?since=",since,
      ifelse(
        stringr::str_length(lang)==0,
        "",
        paste0("?lan=",lang)
      ),
      ifelse(
        stringr::str_length(cat)==0,
        "",
        paste0("?cat=",cat)
      ),
      ifelse(
        stringr::str_length(nocat)==0,
        "",
        paste0("?nocat=",nocat)
      )
    )
  )
}
