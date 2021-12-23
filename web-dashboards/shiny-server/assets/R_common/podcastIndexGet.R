# Dependancies:
# This script was developed on linux/ubuntu and depends on having previously installed these packages: 
# sudo apt install libssl-dev openssl curl libcurl4-openssl-dev 
# Example:
# payload <- podcast_index_get_by_url("https://www.podserve.fm/series/rss/2577/playbyplay.rss")
# https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html
# for more information, see https://api.podcastindex.org/developer_docs

library(httr)
library(jsonlite)
library(digest)

set_podcast_env <- function() {
  if (Sys.getenv("podcastIndexKey") == ""){
    Sys.setenv(
      podcastIndexKey = readLines(file("~/env/podcastIndexKey.txt"))[1]
    )
  }
  if (Sys.getenv("podcastIndexSecret") == ""){
    Sys.setenv(
      podcastIndexSecret = readLines(file("~/env/podcastIndexSecret.txt"))[1]
    )
  }
}

# The search function
podcast_index_get_by_url <- function(feedUrl){
  # Set key and secret
  set_podcast_env()
  api_key <- Sys.getenv("podcastIndexKey")
  api_secret <-  Sys.getenv("podcastIndexSecret")
  if(length(feedUrl)>0){
    
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
      ),")"
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
      url = "https://api.podcastindex.org", 
      path = "/api/1.0/podcasts/byfeedurl",
      query = paste0("url=",feedUrl),
      add_headers(
        `User-Agent` = user_agent,
        `X-Auth-Date` = epoch_time,
        `X-Auth-Key` = api_key,
        Authorization = sha_1,
        Accept = "application/json"
      )
    )
    
    # Comment this line out for production, displays results
    message(jsonlite::prettify(httr::content(response, "text",indent=4)))
    parsed <- jsonlite::fromJSON(httr::content(response, "text"), simplifyVector = FALSE)
    return(parsed)
  } else {
    return(NULL)
  }
}