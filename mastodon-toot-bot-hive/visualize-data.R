#!/usr/bin/env Rscript
# Requires installation of R, at a minimum for apt use:
#     $sudo apt install r-base r-base-core r-recommended
# Version 0.1
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  ggplot2, data.table, dplyr, tidyverse, anytime, 
  rjson, stringr, loggit, gt, webshot
)
# webshot only installs if it's missing or old
suppressMessages(
 webshot::install_phantomjs(force=FALSE)
)
###################
# Local Functions #
###################

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
  seconds_decimal=0,
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
      .years <-round(.seconds / (365.24*24*60*60),0)
      .seconds <- 0
    } else {
      .days <- as.integer((.seconds / (365.24*24*60*60)-.years)*365.24)
      if (.days > 0 ) {
        .days <-round((.seconds / (365.24*24*60*60)-.years)*365.24,0)
        .seconds <- 0
      } else {
        .days_decimal <-(.seconds / (365.24*24*60*60)-.years)*365.24-.days
        .hours <- as.integer(.days_decimal*24)
        if (.hours > 0) {
          .hours <- round(.days_decimal*24,0)
        }else{
          .hours_decimal <- .days_decimal*24 - .hours
          .minutes <- as.integer(.hours_decimal*60)
          .minutes_decimal <- .hours_decimal*60 - .minutes
          if (.minutes > 0) {
            .minutes <- round(.hours_decimal*60,0)
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

int_frequency <- as.integer(
  (max(url_data$timestamp_post)-min(url_data$timestamp_post))/(60*56)
)
pretty_frequency <- .get_pretty_timestamp_diff(
  min(url_data$timestamp_post),
  min(url_data$timestamp_post) + (int_frequency*60)
)
# Sort and filter 
url_summary <- url_data %>% count(domain, sort = TRUE) %>% filter(domain>0) %>% filter(n>1)
names(url_summary)<- c('domain', "url count")
url_summary <- cbind(
  url_summary,round(url_summary$"url count"/(minutes_total),1)
)
url_summary <- cbind(
  url_summary,round((100*url_summary$"url count")/sum(url_summary$"url count"),1)
)
names(url_summary)<- c('domain', "url count","url/minute","share (%)")
# only return the top 25 items for this table
url_summary <- head(url_summary,25)

time_length_display <- .get_pretty_timestamp_diff(
  min(podping_data$timestamp_post),
  max(podping_data$timestamp_post)
)

report_name_prefix <- paste0(Sys.Date(),"_",str_trim(time_length_display, side ="both"))
last_name_prefix <- paste0("last_published_",str_trim(time_length_display, side ="both"))

#############
# visualize #
#############
post_timestamps <- podping_data$timestamp_post %>%
    anytime() %>%
    as.POSIXct()

url_timestamps <- url_data$timestamp_post %>%
    anytime() %>%
    as.POSIXct()

# Graph the top 5 domains
url_domains_to_graph <- head(url_summary$domain,5)
url_domains_to_graph_data <-url_data %>% dplyr::filter(domain %in% url_domains_to_graph )

chart_title <- paste0(
  "Podpings grouped into item count for every ",
  pretty_frequency,
  " over the past ",
  str_trim(time_length_display, side ="both"),
  " for ", Sys.Date()
)

#Sys.Date(),"-",

chart_file_path <- paste0("stats/",report_name_prefix,"-podping-frequency.png")
chart_file_path_last <- paste0("stats/",last_name_prefix,"-podping-frequency.png")


# could filter data to specific time frames...
# create bins
by_mins_urls_bins <- cut.POSIXt(url_timestamps,paste0(int_frequency," mins"))
by_mins_post_bins <- cut.POSIXt(post_timestamps,paste0(int_frequency," mins"))

.get_min_bins <- function (this_domain,y){
  y <-y %>% dplyr::filter(domain == this_domain)
  timestamp <- y$timestamp_post %>%
    anytime() %>%
    as.POSIXct()

  by_mins_domain_bins <-cut.POSIXt(timestamp,paste0(int_frequency," mins"))
  podping_domain_mins <- base::split(timestamp, by_mins_domain_bins)
  per_min_domain_chart_data <- lapply(podping_domain_mins,FUN=length)
  per_min_domain_chart_data_frame <- cbind(
    as.data.frame(anytime(names(per_min_domain_chart_data))),
    as.data.frame(unlist(per_min_domain_chart_data))
  )
  names(per_min_domain_chart_data_frame) <- c("time_bin","frequency")
  # remove last row  
  per_min_domain_chart_data_frame  %>%  head(-1)
}
by_mins_domain_bins <- lapply(
  url_domains_to_graph,
  FUN=.get_min_bins,
  y=url_domains_to_graph_data
)
podping_urls_mins <- base::split(url_timestamps, by_mins_urls_bins)
podping_post_mins <- base::split(post_timestamps, by_mins_post_bins)
per_min_urls_chart_data <- lapply(podping_urls_mins,FUN=length)
per_min_urls_chart_data_frame <- cbind(
  as.data.frame(anytime(names(per_min_urls_chart_data))),
  as.data.frame(unlist(per_min_urls_chart_data))
)
names(per_min_urls_chart_data_frame) <- c("time_bin","frequency")
# remove last row from dataframe 
per_min_urls_chart_data_frame <- head(per_min_urls_chart_data_frame,-1)
per_min_post_chart_data <- lapply(podping_post_mins,FUN=length) %>%
  unlist() %>%
  as.data.frame() %>%
  head(-1)
names(per_min_post_chart_data) <- "frequency"
domain_colors<-c(
  "aquamarine4",
  "azure4",
  "darkolivegreen4",
  "burlywood4",
  "coral4"
)
png(file=chart_file_path,
    width=900, height=600)

plot(
  x=per_min_urls_chart_data_frame$time_bin,
  y=per_min_urls_chart_data_frame$frequency,
  type = "b",
  xlab="Time",
  col="red",
  ylim=c(0,max(per_min_urls_chart_data_frame$frequency)),
  ylab=paste0("Items / ", pretty_frequency),
  lty=1,lwd = 3,cex=1.3,
  main=paste0(chart_title)
)
lines(
  x=per_min_urls_chart_data_frame$time_bin,
  y=per_min_post_chart_data$frequency,
  type="o",lwd = 3,cex=1.3,
  col="blue",
  lty=2
)
lines(
  x=as.data.frame(by_mins_domain_bins[1])$time_bin,
  y=as.data.frame(by_mins_domain_bins[1])$frequency,
  type="l",lwd = 3,cex=1.3,
  col=domain_colors[1],
  lty=1
)
lines(
  x=as.data.frame(by_mins_domain_bins[2])$time_bin,
  y=as.data.frame(by_mins_domain_bins[2])$frequency,
  type="l",lwd = 3,cex=1.3,
  col=domain_colors[2],
  lty=2
)
lines(
  x=as.data.frame(by_mins_domain_bins[3])$time_bin,
  y=as.data.frame(by_mins_domain_bins[3])$frequency,
  type="l",lwd = 3,cex=1.3,
  col=domain_colors[3],
  lty=3
)
lines(
  x=as.data.frame(by_mins_domain_bins[4])$time_bin,
  y=as.data.frame(by_mins_domain_bins[4])$frequency,
  type="l",lwd = 3,cex=1.3,
  col=domain_colors[4],
  lty=4
)
lines(
  x=as.data.frame(by_mins_domain_bins[5])$time_bin,
  y=as.data.frame(by_mins_domain_bins[5])$frequency,
  type="l",lwd = 3,cex=1.3,
  col=domain_colors[5],
  lty=5
)
legend(
  "topleft", 
  legend=c("Url Count","Post Count",url_domains_to_graph), 
  col=c("red","blue",domain_colors), lty=c(1,2,1:5), bg="transparent", lwd = 3, cex=1 
)
dev.off()
# make a copy of the file to link to...
file.copy(from=chart_file_path,to=chart_file_path_last,overwrite=TRUE)

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
# summary_Stats is used for the toot-bot
summary_Stats <- paste0(  
  'Podping hive "custom json" post report ',
  "for the last ",
  str_trim(time_length_display, side ="both"),
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
  "\nDetails at:\n" , 
# While off line pointing to github instead
#  "https://shiny.podping-stats.com/apps/Podping/HostSummary/?version=",
  "https://seakintruth.github.io/podping-stats/mastodon-toot-bot-hive/stats/?version=",
  utils::URLencode(as.character(Sys.time())),
  "\n#podping #Stats"
)
# export to last txt file
if (file.exists("stats/lastSummary.txt")){
  file.remove("stats/lastSummary.txt")
}
fileConn <- file("stats/lastSummary.txt")
writeLines(summary_Stats, fileConn)
close(fileConn)

# Build the reports for the github pages found at:
# https://seakintruth.github.io/podping-stats/mastodon-toot-bot-hive/stats/
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
      str_trim(time_length_display, side ="both"), ""),
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
      "#podping #Stats \n"
    ) 
  ) %>%
  tab_options(
    column_labels.background.color = customGreen0,
    heading.background.color = customGreen, 
    source_notes.background.color = customGreen0,
    table.background.color  = powderBlue
  ) 
# gt::gtsave(formated_summary_table,expand=10,filename="lastest-url-report.png",path="stats")
gt::gtsave(
  formated_summary_table,
  filename=paste0(report_name_prefix,"-url-report.html"),
  path="stats"
)

# Last url Report HTML 
md_last_url_report_html <- paste0(
  read_lines(
    file = paste0("stats/",report_name_prefix,"-url-report.html"),
    skip = 1
  ),
  collapse="\n"
)
# log the same stats
loggit::set_logfile("stats/summaryStats.ndjson")
message(summary_Stats)

.get_ordered_stat_file_list <- function(strStatsFolderName,strPattern){
  files_list <- list.files(strStatsFolderName,pattern=strPattern)
  files_list <- as.data.frame(matrix(c(
    files_list,
    file.mtime(paste0(paste0(strStatsFolderName,"/"),files_list)),
    1:length(files_list)),
    nrow=length(files_list))
  )
  files_list <- files_list  %>% 
    arrange(.,desc(V2)) %>% 
    select(V1) %>% 
    as.vector() %>%
    unlist
}

past_report_files <- .get_ordered_stat_file_list(
  "stats",
  ".html"
)

md_past_reports <-paste0(
  "# Past reports \n",
    paste0(
      "- [",past_report_files,"]",
      "(",past_report_files,")\n",
    collapse=""),
  collapse=""
)
current_chart_files <- .get_ordered_stat_file_list(
  "stats",
  "^last_published_.*png"
)
past_chart_files <- .get_ordered_stat_file_list(
  "stats",
  "*png$"
)
past_chart_files <- past_chart_files[
  !(past_chart_files %in% current_chart_files)
]

md_last_published_charts <- paste0(
  "\n# Charts",  
  paste0(
    "\n[![",current_chart_files,"]",
    "(",current_chart_files,")]",
    "(",current_chart_files,")",
    collapse=""),
  collapse=""
)

md_past_charts <- paste0(
  "\n# Past charts",  
  paste0(
    "\n[![",past_chart_files,"]",
    "(",past_chart_files,")]",
    "(",past_chart_files,")",
    collapse=""),
  collapse=""
)

# Write the stats/index.md github pages files
readr::write_lines(
  paste0(
    "# Domain Stats\n",
    md_last_url_report_html,
    "\n",
    md_last_published_charts,
    md_past_charts,
    md_past_reports,
    collapse=""
  ),
  file = "stats/index.md"
)
