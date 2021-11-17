library(shiny)
library(DBI) # Required by authenticateWithPostgres.R
library(RPostgres) # Required by authenticateWithPostgres.R
library(glue)
library(stringr)
library(ggplot2)

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

# Define UI for application
ui <- fluidPage(
  tags$head(
    tags$link(rel = "apple-touch-icon",href="/apple-touch-icon.png?v=1",sizes = "180x180"),
    tags$link(rel = "icon",type = "image/png",sizes = "32x32",href = "/favicon-32x32.png?v=1"),
    tags$link(rel = "icon", type = "image/png", sizes = "16x16",href = "/favicon-16x16.png?v=1"),
    tags$link(rel = "manifest", href = "/site.webmanifest?v=1"),
    tags$link(rel = "mask-icon", href = "/safari-pinned-tab.svg?v=1",color="#5bbad5"),
    tags$link(rel = "shortcut icon", href = "/favicon.ico?v=1"),
    tags$meta(name = "msapplication-TileColor", content="#da532c"),
    tags$meta(name = "theme-color", content = "#ffffff"),
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../assets/css/main.css"),
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
      HTML(
        '<iframe ',
          'loading="lazy"',
          'frameBorder="0"',
          'src="../app_components/sub_podpings_served/" ',
          'height="25" ',
          'width="100%" ',
          'title="All Time Podpings Served"',
        '>',
        '</iframe>'
      )
    ),
    column(2,
      selectInput(
        inputId = "GroupBySelected",
        label = "Group Url Count By",
        choices = c(
          "Minute" = "minute",
          "hour" = "hour",
          "Day" = "day",
          "Week" = "week",
          "Month" = "month",
          "Year" = "year"
        ),
        selected = "hour"
      )
    ),
    column(2,
      checkboxInput(
        inputId="chkEnableLiveData",
        label="Enable Live Data Updates (refresh every 3 seconds)", 
        value = FALSE,
        width = NULL
      )
    )
  ),
  fluidRow(
    column(12,
      plotOutput("plot", click = "plot_click"),
      verbatimTextOutput("info")
    )
  ),
  fluidRow(
    column(12,
      plotOutput("plot_hist")
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
  pollLastPodpingUrls <- reactivePoll(3000, session,
      # This function returns the last block that was processed
      # and updates if modified
      checkFunc = function() ({
        if (input$chkEnableLiveData) {
            get_last_hive_block_num()
        } else {
          FALSE
        }
      }),
      # This function returns the content
      valueFunc = function() {
        period <- input$GroupBySelected
        url_list <- dbfetch_query_podping(
          paste0(
            "SELECT date_trunc('",
              period,
              "'::text, podping_url_timestamp.\"timestamp\") AS timestamp, ",
              "count(*) AS url_count ",
            "FROM podping_url_timestamp ",
            "GROUP BY (date_trunc('",
              period,
              "'::text, podping_url_timestamp.\"timestamp\"))"
          )
        )
        url_list_return <- as.data.frame(url_list)
        colnames(url_list_return) <- c("Timestamp", "Count")
        # Return
        url_list_return
      }
  )
  # Plot results
  output$plot <- renderPlot({
    podpingData <- pollLastPodpingUrls()
    plot(podpingData$Timestamp, podpingData$Count)
  }, res = 96)

  output$plot_hist <- renderPlot({
    podpingData <- pollLastPodpingUrls()
    boxplot(podpingData$Timestamp ~ podpingData$Count , data=podpingData)
  })

  output$info <- renderPrint({
    req(input$plot_click)
    x <- round(input$plot_click$x, 2)
    y <- round(input$plot_click$y, 2)
    cat("[", x, ", ", y, "]", sep = "")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
