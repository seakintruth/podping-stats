library(shiny)
library(DBI)
library(RPostgres)
library(glue)
# library(feather) # used by hitCounter.R, directly called out...

source("../../../../assets/R_common/hitCounter.R")
source("../../../../assets/R_common/authenticateWithPostgres.R")

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../../assets/css/main.css"),
    tags$title("Podping-Stats")
  ),
  fluidRow(
    htmlOutput("podping_info"),
    htmlOutput("run_once")
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session)
    '<span id=hitcounter></span>'
  })
  pollData <- reactivePoll(3000, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        get_last_hive_block_num()
      }),
    # This function returns the content
    valueFunc = function() {
      format(round(as.numeric(get_podpings_served()$count), 0), nsmall=0, big.mark=",")
    }
  )
  output$podping_info <- renderPrint({

    handle_client_query_value <- function(session) {
        query <- parseQueryString(session$clientData$url_search)
        # Return a string with key-value pairs
    }




    # Not used, just called to save info
    #g_client_data <- handle_client_query(session)
    # This is the results
    cat(paste0("Podpings Served: <span id=podpings_served>",pollData(),"</span>"))
  }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
