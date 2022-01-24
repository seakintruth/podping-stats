
#dev testing stuff
# setwd("/srv/shiny-server/apps/Podping/Dashboard/")
# [TODO] review streaming data visulizations with plotly
# https://plotly-r.com/linking-views-with-shiny.html#shiny-performance

library(datasets)       # for testing
library(shiny)          # Shiny applications
library(DBI)            # Required by authenticateWithPostgres.R
library(RPostgres)      # Required by authenticateWithPostgres.R
library(glue)           # fast concat
library(stringr)        # handle strings
library(tidyverse)      # data manipulation and viz
library(tidyr)
library(anytime)        # date stuff
library(lubridate)      # more date stuff
library(feather)        # fast to and from disk caching
library(data.table)     # for fast write data to csv with fwrite
library(dygraphs)       # for interactive time series charts
library(xts)            # To make the convertion data-frame / xts format for dygraphs
#library(ggplot2)        # plotting
#library(ggthemes)       # themes for ggplot2
#library(ggeasy)         # https://www.infoworld.com/article/3533453/easier-ggplot-with-the-ggeasy-r-package.html
#library(extrafont)      # nice font
#library(RColorBrewer)   # colors
#library(viridis)        # the best color palette
#library(rgdal)          # deal with shapefiles
#library(microbenchmark) # measure the speed of executing

#-----------------------------------------------------------------------#
# Ultimately the files sourced here should be a new package             #
# just replace these source calls with a single library('podpingStats') #
#-----------------------------------------------------------------------#
        
# Loads the function hit_counter
source("../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../assets/R_common/authenticateWithPostgres.R")
# Loads podcastindex api query functions
source("../../../assets/R_common/podcastIndexGet.R")

createPodpingCacheFile <- function(){
  # Load all the data globally, once, takes roughly 2 seconds per million records
  data_return <- dbfetch_query_podping(
    "SELECT * FROM podping_url_timestamp"
  )
  feather::write_feather(data_return,"podping_data_cache.feather")
  data_return
}

# For the dashboard cache this to local file for everyone once an hour
if (file.exists("podping_data_cache.feather")){
  if (file.info("podping_data_cache.feather")$mtime>(Sys.time()-(60*60))){
    # just load the file
    podping_data_global <- feather::read_feather("podping_data_cache.feather")
  } else {
    # Re-create the file
    podping_data_global <- createPodpingCacheFile()
  }
} else {
  #create the file
   podping_data_global <- createPodpingCacheFile()
}
podping_data_cache_file_last_modified <- file.info("podping_data_cache.feather")$mtime
podping_data_global$host <- as.factor(podping_data_global$host)

# Define UI for application
ui <- fluidPage(
  tags$head(
    tags$link(
      rel = "apple-touch-icon",
      href="/apple-touch-icon.png?v=1",
      sizes = "180x180"
    ),
    tags$link(
      rel = "icon",
      type = "image/png",
      sizes = "32x32",
      href = "/favicon-32x32.png?v=1"
    ),
    tags$link(
      rel = "icon", 
      type = "image/png", 
      sizes = "16x16",
      href = "/favicon-16x16.png?v=1"
    ),
    tags$link(
      rel = "manifest", 
      href = "/site.webmanifest?v=1"
    ),
    tags$link(
      rel = "mask-icon", 
      href = "/safari-pinned-tab.svg?v=1",
      color="#5bbad5"
    ),
    tags$link(
      rel = "shortcut icon", 
      href = "/favicon.ico?v=1"
    ),
    tags$meta(
      name = "msapplication-TileColor", 
      content="#da532c"
    ),
    tags$meta(
      name = "theme-color", 
      content = "#ffffff"
    ),
    tags$link(
      rel = "stylesheet", 
      type = "text/css",
      href = "../../../assets/css/main.css"
    ),
    tags$title("Podping-Stats")
  ),
  fluidRow(
    HTML(
      '<div class="topnav">
      <a class="active" href="https://shiny.podping-stats.com/">Stats</a>
      <a href="https://www.podping-stats.com/index.html">Toot Bot Reports</a>
      <a href="https://www.podping-stats.com/contact.html">Contact</a>
      <a href="https://www.podping-stats.com/about.html">About</a>'
    ),
    htmlOutput("run_once"),
    HTML('</div>')
  ),
  fluidRow(
    column(3,
      HTML(
        paste0(
          '<h2>',
          '<u>Podping Descriptive</u>',
          '</h2>',
          '<p>Descriptive Statistics of all Podpings on the Hive blockchain',
            '<iframe ',
              'loading="lazy"',
              'frameBorder="0"',
              'src="../app_components/sub_podpings_served/" ',
              'height="25" ',
              'width="100%" ',
              'title="All Time Podpings Served"',
            '>',
            '</iframe>',
          '</p>'
        )
      )
    ),
    column(9,
      HTML(
        '<h3>
        Analyzing <a href="https://peakd.com/podcasting2/@podping/overview-and-purpose-of-podpingcloud-and-the-podping-dapp">
          <img src="../../../assets/images/podping_logo.png" width=50 hight=50 alt="podping logo" /> 
          Podping
        </a> on
        <a href="https://hive.io/">
          <img src="../../../assets/images/hive_logo.png" width=50 hight=50 alt="Hive.io logo"/>
          blockchain
        </a> as envisioned by<span id=podcast_index_logo>
          <a href="https://podcastindex.org/">
            <img src="../../../assets/images/podcast_index_logo.jpeg" width=150px />
          </a>
        </span>
      </h3>'
      )
    )
  ),
  # Show a plot of the generated distribution
  # Main panel for displaying outputs ----
  fluidRow(
    # Input: Selector for choosing dataset ----
    column(2,
      dateRangeInput(
        inputId = "DateRangeFilter",
        label = "Date Range",
        start = Sys.Date()-31,
        end = Sys.Date(),
        min = "2021-05-18",
        max = Sys.Date()+1,
        format = "mm/dd/yyyy", #yyyy-mm-dd
        startview = "year",
        weekstart = 0,
        language = "en",
        separator = " to ",
        width = NULL,
        autoclose = TRUE
      )
    ),
    column(2,
      selectInput(
        inputId = "GroupBySelected",
        label = "Group Url Count By Period",
        choices = c(
          "None" = "none",
          "30 Seconds" = "30second",
          "Minute" = "minute",
          "15 Minutes" = "15minute",
          "30 Minutes" = "30minute",
          "Hour" = "hour",
          "Day" = "day",
          "Week" = "week",
          "Month" = "month",
          "Year" = "year"
        ),
        selected = "hour"
      )
    ),
    column(
      3,
      downloadButton(
        "downloadSelectedData",
        ".csv Download Selected Date Range URL Timestamp Data"
      )
    ),
    column(
      3,
      downloadButton(
        "downloadData",
        ".csv Download ALL URL Timestamp Data"
      )
    )
  ),
  fluidRow(
    column(
      12,
      dygraphOutput("urls_per_period_chart")
    )
  ),
  fluidRow(
    column(
      12,
      dygraphOutput("urls_per_period_by_host_chart")
    )
  ),
  fluidRow(
    column(
      6,
      plotOutput("plot_hist")
    ),
    column(
      6,
      verbatimTextOutput("data_summary")
    )
  ),
  fluidRow(
    column(
      6,
      verbatimTextOutput("data_last_modified")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session)
    paste0('<span id=hitcounter style="display:none;">', anytime::rfc3339(Sys.time()), "</span>")
  })

  # A reactive function only runs once, and results are cached for 
  # use by multiple output calls.
  getDataFromSelected <- reactive({
    # using min and max instead of input$DateRangeFilter[1]...
    # this allows the user to flip range and not break the app
    #dateRangeMin <- min(input$DateRangeFilter)
    #dateRangeMax <- max(input$DateRangeFilter)
    dateRangeMin <- input$DateRangeFilter[1]
    dateRangeMax <- input$DateRangeFilter[2]
    period <- input$GroupBySelected
    
    # assign the global data to filtered variable
    podping_data_filtered <- podping_data_global

    podping_data_filtered <- dplyr::filter(
      podping_data_filtered,
      timestamp >= dateRangeMin,
      timestamp <= dateRangeMax+1
    )
    # setup period field for grouping
    # this list of if, else if's should be restructured as some sort of 
    # mapping of podping_data_filtered$timestamp with breaks ?
    periodBreak <- switch(
      EXPR = period,
      "30second" = "30 sec" ,
      "minute" = "1 min",
      "15minute" = "15 min",
      "30minute" = "30 min",
      "day" = "1 day",
      "hour" = "1 hour",
      "week" = "1 week",
      "month" = "1 month",
      "year" = "1 year",
      "none"
    )
    if(periodBreak == "none") {
      podping_data_filtered$period <- podping_data_filtered$timestamp
    } else {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = periodBreak
      )
    }
    # Return data
    podping_data_filtered
  })
  timeSinceLoad <- reactive({
    tmp <- getDataFromSelected()
    round(proc.time(),2)['elapsed']
  })
  output$downloadData <- downloadHandler(
    filename = function() {
      paste('Podping_Urls_by_Timestamp_ALL_',format(Sys.time(), "%Y-%m-%d_%H_%M_%S"),'.csv', sep='')
    },
    content = function(file) {
      data.table::fwrite(data.table::as.data.table(podping_data_global), file, row.names = TRUE)
    }
  )
  output$downloadSelectedData <- downloadHandler(
    filename = function() {
      paste(
        'Podping_Urls_by_Timestamp_Selected_',
        format(input$DateRangeFilter[1], "%Y-%m-%d"),
        '_to_',
        format(input$DateRangeFilter[2], "%Y-%m-%d"),
        '.csv',
        sep=''
      )
    },
    content = function(file) {
      data.table::fwrite(data.table::as.data.table(getDataFromSelected()), file, row.names = TRUE)
    }
  )
  output$plot_hist <- renderPlot({
    podpingData <- getDataFromSelected()
    podpingDataCount <- dplyr::count(podpingData,period)
    hist(
      podpingDataCount$n,
      col = "lightblue",
      main = paste0(
        "Histogram of URLs per ",
        ifelse(
          input$GroupBySelected == "none",
          "Block",
          paste0(
            input$GroupBySelected," period"
          )
        )
      )
    )
    # Draw the normal distribution line for this data
    l<-rnorm(1000000, mean(podpingDataCount$n), sd(podpingDataCount$n))
    lines(density(l), col="red")

  })
  output$data_summary <- renderPrint({
    podpingData <- getDataFromSelected()
    #[TODO] write a usefull summary...
    summary(dplyr::select(podpingData,host, timestamp,block_number))
  })
  output$data_last_modified <- renderPrint({
    cat("Data source last cached:", anytime::rfc3339(podping_data_cache_file_last_modified),"
Time since session load:", timeSinceLoad(), " seconds")
  })
  output$urls_per_period_chart <- renderDygraph({
    podpingData <- getDataFromSelected()
    podpingDataCount <- dplyr::count(podpingData,period)
    podpingDataCount$period <- anytime::anytime(podpingDataCount$period)
    # xts format (time series):
    xts_podpingData <- xts::xts(x=podpingDataCount, order.by=podpingDataCount$period)
    results_dygraph <- dygraph(
      xts_podpingData,
      group = "url_timestamp_count_group",
      xlab = "Date / Time",
      ylab = "Url Count",
      main = paste0( 
        "Podping url updates per period:", input$GroupBySelected
      )
    )
    results_dygraph <- dyRangeSelector(
      results_dygraph 
    )
    results_dygraph
  })

  output$urls_per_period_by_host_chart <- renderDygraph({
    podpingData <- data.table::as.data.table(getDataFromSelected())
    podpingData$period <- anytime::anytime(podpingData$period)
    podpingDataCounting <- podpingData[,.(count=.N), by = .(period,host)]
    podpingDataCounting <- tidyr::pivot_wider(podpingDataCounting,names_from="host",values_from ="count")
    # xts format (time series):
    xts_podpingData <- xts::xts(podpingDataCounting, order.by=podpingDataCounting$period)

    results_dygraph <- dygraph(
      xts_podpingData,
      group = "url_timestamp_count_group",
      xlab = "Date / Time",
      ylab = "Url Count per Host",
      main = paste0( 
        "Podping url updates for each host per period:", input$GroupBySelected
      )
    )
    results_dygraph <- dyRangeSelector(
      results_dygraph 
    )
    results_dygraph
  })
}

# Run the application
shinyApp(ui = ui, server = server)
