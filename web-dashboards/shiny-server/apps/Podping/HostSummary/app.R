library(shiny)
library(DBI) # Required by authenticateWithPostgres.R
library(RPostgres) # Required by authenticateWithPostgres.R
library(glue)
library(feather) # Requried by hitCounter.R

#-----------------------------------------------------------------------#
# Ultimately the files sourced here should be a new package             #
# just replace these source calls with a single library('podpingStats') #
#-----------------------------------------------------------------------#
# Loads the funciton hit_counter
source("../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../assets/R_common/authenticateWithPostgres.R")


# Define UI for application
ui <- fluidPage( 
  tags$head(
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
        '<h2>
          <u>Host Summary</u>
        </h2>'
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
    column(3,
      checkboxInput(
        inputId="chkEnableLiveData",
        label="Enable Live Data Updates", 
        value = FALSE,
        width = NULL
      )  
    ),
    column(3,
    numericInput(
            inputId = "minutesOfHistory",
            label = "Time frame in minutes:", 
            value = 60*24
        )    
    ),
    column(3,
      verbatimTextOutput("podings_served")
    ),
    column(3,
      verbatimTextOutput("summary_info")
    )
  ),
  fluidRow(
    column(6,
      plotOutput("histoPlot")
    ),
    column(6,
      DT::dataTableOutput("results_table")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session)
    '<span id=hitcounter></span>'
  })

  pollData <- reactivePoll(2500, session,
  # This function returns the last block that was processed and updates if modified
  checkFunc = function() ({
      if (input$chkEnableLiveData) {
        get_last_hive_block_num()
      } else {
        FALSE
      }
    }),
    # This function returns the contenT
    valueFunc = function() {
      get_host_summary(input$minutesOfHistory)
    }
  )

  pollLastBlock <- reactivePoll(3000, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_hive_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the contenT
    valueFunc = function() {
      get_last_hive_block_num()
    }
  )

  pollPodPingsServed <- reactivePoll(9000, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_hive_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the content
    valueFunc = function() {
      format(round(as.numeric(get_podpings_served()$count), 0), nsmall=0, big.mark=",")        # nolint
    }
  )
  output$podings_served <- renderPrint({
    cat(paste0("Alltime Podpings Served:",pollPodPingsServed()))
  })
  output$summary_info <- renderPrint({
    cat(paste0("Last block processed:",pollLastBlock()))
  })
  # choose columns to display
  output$results_table <- DT::renderDataTable({
    DT::datatable(pollData())
  })
  # Output the histogram of results
  output$histoPlot <-renderPlot({
    tmp_data <- pollData()
    tmp_data <- tmp_data[order(tmp_data$count),]
    # Rotate the y axis labels
    par(las=2)
    # Increase margin size
    par(mar=c(4,11,4,4))
    barplot(
      as.integer(tmp_data$count),
      main="Host Distribution", 
      horiz=TRUE,
      names.arg=tmp_data$host
    )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
