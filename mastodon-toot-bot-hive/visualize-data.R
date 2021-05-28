#!/usr/bin/env Rscript
# Requires installation of R, at a minimum for apt use:
#     $sudo apt install r-base r-base-core r-recommended
# Version 0.1
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  psych, ggplot2, table1, patchwork,
  data.table, dplyr, tidyverse, anytime, 
  rjson, stringr, loggit, tidygraph, gt,webshot
)
# webshot only installs if it's missing or old
suppressMessages(
 webshot::install_phantomjs(force=FALSE)
)
###################
# Local Functions #
###################
# Posts per minute
plot_events_per_frequency <- function(
  event_vals, 
  chart_title, 
  intPerMinutes, 
  display_frequency,
  file_name
) {
  event_vals <- event_vals %>%
    anytime() %>%
    as.POSIXct()
  # create bins
  by_mins_podpings <- cut.POSIXt(event_vals,paste0(intPerMinutes," mins"))
  podping_data_mins <- split(event_vals, by_mins_podpings)
  per_min_chart_data <- lapply(podping_data_mins,FUN=length)
  per_min_chart_data_frame <- cbind(
    as.data.frame(anytime(names(per_min_chart_data))),
    as.data.frame(unlist(per_min_chart_data))
  )
  names(per_min_chart_data_frame) <- c("time_bin","frequency")
  png(file=paste0("stats/",file_name,".png"),
      width=900, height=600)

  # remove last row from dataframe 
  per_min_chart_data_frame <- head(per_min_chart_data_frame,-1)
  
  plot(
    x=per_min_chart_data_frame$time_bin,
    y=per_min_chart_data_frame$frequency,
    type = "l",
    xlab="Time",
    ylab=paste0("items / ", display_frequency),
    main=paste0(chart_title)
  )
  
  
  dev.off()
}

.getUrlFromPostJson <- function(x) {
  rjson::fromJSON(
    x, 
    unexpected.escape = "skip", 
    simplify = TRUE
  )$urls
}

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
####################
# read in the data #
####################
if (file.exists("data-podping.csv")) {
  podping_data <- fread(file="data-podping.csv") 
}
if (file.exists("data-unauthorized.csv")) {
  podping_unathorized_data <- fread(file="data-unauthorized.csv")
}
if (file.exists("data-not-podping_firehose.csv")) {
  not_podping_data <- fread(file="data-not-podping_firehose.csv")
}
if (file.exists("data-podping-url.csv")) {
  url_data <- fread(file="data-podping-url.csv")
}
# if (exists("podping_unathorized_data")) {
  # For now not enough to bother analyzing seperetly
#  not_podping_data <- rbind(not_podping_data,podping_unathorized_data)
#}
if (exists("not_podping_data")) {
  count_not_podping_data_unique <- data.table::uniqueN(not_podping_data)
}
count_podping_data_unique <- data.table::uniqueN(podping_data)

##################
# clean the data #
##################
minutes_total <- 
  (max(podping_data$timestamp_post)-min(podping_data$timestamp_post)) / 60

intFrequency <- as.integer(
  (max(url_data$timestamp_post)-min(url_data$timestamp_post))/(60*56)
)

pretty_frequency <- .get_pretty_timestamp_diff(
  min(url_data$timestamp_post),
  min(url_data$timestamp_post) + (intFrequency*60)
)
url_summary <- url_data %>% count(domain, sort = TRUE) %>% filter(domain>0) %>% filter(n>1)
names(url_summary)<- c('domain', "url count")
url_summary <- cbind(
  url_summary,round(url_summary$"url count"/(minutes_total),1)
)
url_summary <- cbind(
  url_summary,round((100*url_summary$"url count")/sum(url_summary$"url count"),1)
)
names(url_summary)<- c('domain', "url count","url/minute","share (%)")

time_length_display <- .get_pretty_timestamp_diff(
  min(podping_data$timestamp_post),
  max(podping_data$timestamp_post)
)

report_name_prefix <- paste0(Sys.Date(),"-",str_trim(time_length_display, side ="both"))

#############
# visualize #
#############
plot_events_per_frequency(
  url_data$timestamp_post, 
  paste0(
    "Podpings grouped into url count for every ",
    pretty_frequency,
    " over the past ",
    time_length_display
  ),
  intFrequency,
  pretty_frequency,
  "podping-url-frequency"
)

# could filter data to specific time frames...
plot_events_per_frequency(
  podping_data$timestamp_post,
  paste0(
    "Podpings grouped into post counts for every ",
    pretty_frequency,
    " over the past ",
    time_length_display
  ),
  intFrequency,
  pretty_frequency,
  "podping-post-frequency"
)

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

podping_data$json_url <- lapply(podping_data$json,.getUrlFromPostJson)
podcastUrls <- unlist(podping_data$json_url)

if (exists("not_podping_data")) {
  summary_stats_not_podping_data <- paste0(
    'All other "custom json" hive post count is ',
    count_not_podping_data_unique,
    " (", round(count_not_podping_data_unique/minutes_total,2),
    " posts/min)\n\t",
    'Podping portion of all "custom json" posts on hive.io is ',
    round(
      100 * count_podping_data_unique / 
        (count_podping_data_unique+count_not_podping_data_unique),
      5
    ),"%\n"
  )
} else {
  summary_stats_not_podping_data <- ""
}

###########
# predict #
###########
#[TODO]

##############################
# Summary Statistics Reports #
##############################
summary_Stats <- paste0(  
  'Podping hive "custom json" post report ',
  "for the last ",
  time_length_display,
  ":\n\t",
  "Post count is ",
  count_podping_data_unique, 
  " (", round(count_podping_data_unique/minutes_total,2),
  " posts/min)\n\t",
  "Total urls posted is ", 
  length(podcastUrls), 
  " of which ",
  length(unique(podcastUrls)),
  " are unique\n\t",
  "\t(average of ",
  round(length(podcastUrls)/count_podping_data_unique,2),
  " urls/post)\n\t", summary_stats_not_podping_data,
  "#podping #Stats \n" , 
  "https://seakintruth.github.io/podping-stats/mastodon-toot-bot-hive/stats/",
  utils::URLencode(
    paste0(report_name_prefix,"-url-report.html")
  )
)
# export to last txt file
fileConn <- file("stats/lastSummary.txt")
writeLines(summary_Stats, fileConn)
close(fileConn)

# url count Summary:

customGreen0 = "#DeF7E9"
customGreen = "#71CA97"
customRed = "#FF7F7F"
powderBlue = "#B0E0E6"
formated_summary_table <- gt::gt(url_summary) %>% 
  tab_header(
    title = paste0(  
      'Podping report ',
      "for the last ",
      time_length_display, ""),
    subtitle = "Podping urls are 'custom json' posts on the Hive.io block chain"
  ) %>% 
  gt::tab_source_note(
    paste0(  
      "Total urls posted is ", 
      length(podcastUrls), 
      " of which ",
      length(unique(podcastUrls)),
      " are unique\n\t",
      "\t(average of ",
      round(length(podcastUrls)/count_podping_data_unique,2),
      " urls/post)\n\t", summary_stats_not_podping_data,
      "#podping #Stats \n" , 
      "https://seakintruth.github.io/podping-stats/mastodon-toot-bot-hive/stats/"
    ) 
  ) %>%
  tab_options(
    column_labels.background.color = customGreen0,
    heading.background.color = customGreen, 
    source_notes.background.color = customGreen0,
    table.background.color  = powderBlue
  )

gt::gtsave(formated_summary_table,expand=10,filename="lastest-url-report.png",path="stats")

gt::gtsave(
  formated_summary_table,
  filename=paste0(report_name_prefix,"-url-report.html"),
  path="stats"
)
fCopyComplete <- file.copy(
  paste0("stats/",report_name_prefix,"-url-report.html"),
  "stats/last-url-report.html",TRUE
)

# Last url Report HTML 
md_last_url_report_html <- paste0(read_lines(file = "stats/last-url-report.html",skip = 1),collapse="\n")

# log the same stats
loggit::set_logfile("stats/summaryStats.ndjson")
message(summary_Stats)

md_past_reports <-paste0(
  "# Past reports \n",
    paste0(
      "- [",list.files("stats",pattern="*.html"),"]",
      "(",list.files("stats",pattern="*.html"),")\n",
    collapse=""),
  collapse=""
)

md_past_charts <- paste0(
  "\n# Past charts",  
  paste0(
    "\n- ![",list.files("stats",pattern="*.png"),"]",
    "(",list.files("stats",pattern="*.png"),")",
    collapse=""),
  collapse=""
)

      
# Write the stats/index.md github pages files
readr::write_lines(
  paste0(
    "# Domain Stats\n",
    md_last_url_report_html,
    "# Summary Stats \n",
    summary_Stats,
    "\n",
    md_past_reports,
    md_past_charts, collapse=""
  ),
  file = "stats/index.md"
)
  