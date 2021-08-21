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
source("../../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../../assets/R_common/authenticateWithPostgres.R")


# Shiny doesn't appear to allow generating anything other than HTML content, 
# this is fake JSON and would likely confuse anyone that attempted to use it
# would need to look into CRAN plumber package...

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$title("Podping-Stats/api/v1/podpings-served-fake-JSON")
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

  output$podping_info <- renderPrint({
    # This is the results
    cat(paste0('{["Podpings Served":',get_podpings_served()$count,']}'))
  }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
