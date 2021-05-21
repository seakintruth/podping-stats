#!/usr/bin/env Rscript
# Requires installation of R, at a minimum for apt use:
#     $sudo apt install r-base r-base-core r-recommended
# Version 0.1
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  psych, ggplot2, table1, patchwork,
  data.table, dplyr,tidyverse, anytime, 
  rjson, stringr, loggit, tidygraph
)
if (file.exists("data.csv")) {
  podping_data <- fread(file="data.csv") 
}
if (file.exists("data-unauthorized.csv")) {
  podping_unathorized_data <- fread(file="data-unauthorized.csv")
}
if (file.exists("data-not-podping_firehose.csv")) {
  not_podping_data <- fread(file="data-not-podping_firehose.csv")
}
if (exists("podping_unathorized_data")) {
  # For now not enough to bother analyzing seperetly
  not_podping_data <- rbind(not_podping_data,podping_unathorized_data)
}
count_not_podping_data_unique <- data.table::uniqueN(not_podping_data)
count_podping_data_unique <- data.table::uniqueN(podping_data)

minutes_watching <- 
  (max(podping_data$timestamp_post)-min(podping_data$timestamp_post)) / 60

# Posts per minute #
####################
write_plot_posts_per_min <- function(data_vals, chart_title) {
  data_vals$posix_time_post <- data_vals$timestamp_post %>%
    anytime() %>%
    as.POSIXct()
  # create bins
  by_mins_podpings <- cut.POSIXt(data_vals$posix_time_post,"1 mins")
  podping_data_mins <- split(data_vals$block_num, by_mins_podpings)
  per_min_chart_data <- lapply(podping_data_mins,FUN=length)
  per_min_chart_data_frame <- cbind(
    as.data.frame(anytime(names(per_min_chart_data))),
    as.data.frame(unlist(per_min_chart_data))
  )
  names(per_min_chart_data_frame) <- c("time_bin","frequency")
  png(file=paste0("stats/",chart_title,".png"),
      width=900, height=600)

  plot(
    x=per_min_chart_data_frame$time_bin,
    y=per_min_chart_data_frame$frequency,
    type = "l",
    xlab="Time",
    ylab="Posts / Minute",
    main=paste0(chart_title, "Post Frequency")
  )
  dev.off()
}
# could filter data to specific time frames...
write_plot_posts_per_min(podping_data,"podping_posts_per_minute")
write_plot_posts_per_min(not_podping_data,"Not_podping_posts_per_minute")

# podping_data
######################
# get the URLs from the json objects
# starting descriptive stats with
# https://bookdown.org/wadetroberts/bookdown-demo/descriptive-statistics-and-data-visualization.html

# json_str = stringr::str_replace_all(podping_data$json[1],"\\\\n",""),
# need to de-prettify the json
podping_data$json  <- podping_data$json %>% 
  stringr::str_replace_all("\\\\n","") %>%
  stringr::str_replace_all("'","")  %>%
  stringr::str_replace_all('\\"\\"','\\"') 

.getUrlFromPostJson <- function(x) {
  rjson::fromJSON(
    x, 
    unexpected.escape = "skip", 
    simplify = TRUE
  )$urls
}

podping_data$json_url <- lapply(podping_data$json,.getUrlFromPostJson)
podcastUrls <- unlist(podping_data$json_url)
length(podcastUrls)
length(unique(podcastUrls))
# Display stuff #
#################
.get_pretty_timestamp_diff <- function(
  start_timestamp,
  end_timestamp,
  seconds_decimal=2,
  round_simple=TRUE
){
  # Set defaults
  .days_decimal <- 0
  .days <- 0
  .hours_decimal <- 0
  .hours <- 0
  .minutes_decimal <- 0
  .minutes <- 0
  .seconds_display <- 0
  .seconds <- (end_timestamp-start_timestamp) 
  if (round_simple) {
    .years <- as.integer(.seconds / (365.24*24*60*60))
    if (.years > 0) {
      .years <-round(.seconds / (365.24*24*60*60),1)
      .seconds <- 0
    } else {
      .days <- as.integer((.seconds / (365.24*24*60*60)-.years)*365.24)
      if (.days > 0 ) {
        .days <-round((.seconds / (365.24*24*60*60)-.years)*365.24,1)
        .seconds <- 0
      } else {
        .days_decimal <-(.seconds / (365.24*24*60*60)-.years)*365.24-.days
        .hours <- as.integer(.days_decimal*24)
        if (.hours > 0) {
          .hours <- round(.days_decimal*24,1)
        }else{
          .hours_decimal <- .days_decimal*24 - .hours
          .minutes <- as.integer(.hours_decimal*60)
          .minutes_decimal <- .hours_decimal*60 - .minutes
          if (.minutes > 0) {
            .minutes <- round(.hours_decimal*60,1)
            .hours_decimal <- 0
            .seconds_display <- 0    
          } else {
            .seconds_display <-1 # round(.seconds,seconds_decimal)
          }
       }
      }
    }
  } else {
    .years <- as.integer(.seconds / (365.24*24*60*60))
    .days <- as.integer((.seconds / (365.24*24*60*60)-.years)*365.24)
    .days_decimal <-(.seconds / (365.24*24*60*60)-.years)*365.24-.days
    .hours <- as.integer(.days_decimal*24)
    .hours_decimal <- .days_decimal*24 - .hours
    .minutes <- as.integer(.hours_decimal*60)
    .minutes_decimal <- .hours_decimal*60 - .minutes
    .seconds_display <- round(.minutes_decimal*60,seconds_decimal)
  }
  .time_statement_list <- c(
    ifelse(as.integer(.years),
      ifelse((.years == 1)," year ",paste0(.years," years ")),
      NA
    ),
    ifelse(as.integer(.days),
      ifelse((.days == 1)," day ",paste0(.days," days ")),
      NA
    ),
    ifelse(as.integer(.hours),
      ifelse((.hours == 1)," hour ",paste0(.hours," hours ")),
      NA
    ),
    ifelse(as.integer(.minutes),
      ifelse((.minutes == 1)," minute ",paste0(.minutes," minutes ")),
      NA
    ),
    ifelse(as.integer(.seconds_display),
      ifelse(
        (.seconds_display == 1),
        " second ",
        paste0(.seconds_display," seconds ")
      ),
      NA
    )
  )
  .time_statement_list <- na.omit(.time_statement_list)
  ifelse(
    (length(.time_statement_list) <= 1),
    .time_statement_list[1],
  paste0(
      paste0(
          .time_statement_list[1:(length(.time_statement_list)-1)],
          collapse=""
      ),
      "and ",
      .time_statement_list[length(.time_statement_list)]
    )
  )
}

time_length_display <- .get_pretty_timestamp_diff(
  min(podping_data$timestamp_post),
  max(podping_data$timestamp_post)
)

# Summary Statistics to Log #
#############################
summary_Stats <- paste0(  
  'Podping hive "custom json" post report:\n\t',
  "For the last ",
  time_length_display,
  "\n\t",
  "Post count is ",
  count_podping_data_unique, 
  " (", round(count_podping_data_unique/minutes_watching,2),
  " posts/min)\n\t",
  "Total urls posted is ", 
  length(podcastUrls), 
  " of which ",
  length(unique(podcastUrls)),
  " are unique\n\t",
  "\t(average of ",
  round(length(podcastUrls)/count_podping_data_unique,2),
  " urls/post)\n\t",
  'All other "custom json" hive post count is ',
  count_not_podping_data_unique,
  " (", round(count_not_podping_data_unique/minutes_watching,2),
  " posts/min)\n\t",
  'Podping portion of all "custom json" posts on hive.io is ',
  round(
    100 * count_podping_data_unique / 
      (count_podping_data_unique+count_not_podping_data_unique),
    5
  ),"%",
  "\n#podping #Stats"
)
# export to last txt file
fileConn<-file("stats/lastSummary.txt")
writeLines(summary_Stats, fileConn)
close(fileConn)
# log the same stats
loggit::set_logfile("stats/summaryStats.ndjson")
message(summary_Stats)