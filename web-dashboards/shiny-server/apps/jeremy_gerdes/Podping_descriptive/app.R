#dev testing stuff
#setwd("/srv/shiny-server/apps/jeremy_gerdes/Podping_descriptive/")
library(shiny)
library(DBI) # Required by authenticateWithPostgres.R
library(RPostgres) # Required by authenticateWithPostgres.R
library(glue)
library(stringr)
library(ggplot2)
# https://www.infoworld.com/article/3533453/easier-ggplot-with-the-ggeasy-r-package.html
library(ggeasy) 
library(lubridate)

#library(feather) # Requried by hitCounter.R

#-----------------------------------------------------------------------#
# Ultimately the files sourced here should be a new package             #
# just replace these source calls with a single library('podpingStats') #
#-----------------------------------------------------------------------#
# Loads the funciton hit_counter
source("../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../assets/R_common/authenticateWithPostgres.R")
# Loads podcastindex api query functions
source("../../../assets/R_common/podcastIndexGet.R")

# Load all the data globally, once, takes roughly 2 seconds per million records
podping_data_global <- dbfetch_query_podping(
  "SELECT * FROM podping_url_timestamp"
)
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
        start = "2021-05-01",
        end = Sys.Date(),
        min = "2021-05-01",
        max = Sys.Date(),
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
        selected = "week"
      )
    )
  ),
  fluidRow(
    column(6,
      plotOutput("plot", click = "plot_click"),
      verbatimTextOutput("info")
    ),
    column(6,
      plotOutput("plot_hist")
    )
  ),
  fluidRow(
    column(12,
           verbatimTextOutput("data_summary")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  startTime <- Sys.time()
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session)
    paste0("<span id=hitcounter>", client_query_processed, "</span>")
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
    if (period == "none") {
      podping_data_filtered$period <- podping_data_filtered$timestamp
    } else if (period == "30second") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "30 sec"
      )
    } else if (period == "minute") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "1 min"
      )
    } else if (period == "15minute") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "15 min"
      )
    } else if (period == "30minute") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "30 min"
      )
    } else if (period == "day") {
      podping_data_filtered$period <- as.Date(
        podping_data_filtered$timestamp
      )
    } else if (period == "hour") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "1 hour"
      )
    } else if (period == "week") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "1 week"
      )
    } else if (period == "month") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "1 month"
      )
    } else if (period == "year") {
      podping_data_filtered$period <- cut(
        podping_data_filtered$timestamp,breaks = "1 year"
      )
    }
    #podping_data_filtered$period <- as.POSIXct(
    #  podping_data_filtered$period
    #)
    
    # Return data
    podping_data_filtered
  })

  # Plot results
  output$plot <- renderPlot({
    podpingData <- getDataFromSelected()
    podpingDataCount <- dplyr::count(podpingData,period)
    # snakecase::to_any_case(df,case = "title")
    graphics::plot(
      x=podpingDataCount$period, 
      y=podpingDataCount$n,
      type="b",
      xlab = "Date / Time",
      ylab = "Url Count",
      main = paste0( 
        "Podping url updates per period:" , input$GroupBySelected
      )
    )
  }, res = 96)
  # for if the user clicks on the plot
  output$info <- renderPrint({
    req(input$plot_click)
    x <- round(input$plot_click$x, 2)
    y <- round(input$plot_click$y, 2)
    cat("[", x, ", ", y, "]", sep = "")
  })
  
  output$plot_hist <- renderPlot({
    podpingData <- getDataFromSelected()
    podpingDataCount <- dplyr::count(podpingData,period)
    hist(podpingDataCount$n, col = "lightblue",main=paste0("Histogram of URLs per ",input$GroupBySelected," period"))
  })

  output$data_summary <- renderPrint({
    podpingData <- getDataFromSelected()
    #[TODO] write a usefull summary...
    summary(dplyr::select(podpingData,host, timestamp,block_number))
  })

}

# Run the application
shinyApp(ui = ui, server = server)
