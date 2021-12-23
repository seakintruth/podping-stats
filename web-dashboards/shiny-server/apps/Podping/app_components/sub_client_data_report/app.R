library(shiny)
library(DBI)
library(RPostgres)
library(glue)
# library(feather) # used by hitCounter.R, directly called out...

source("../../../../assets/R_common/clientDataReport.R")

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../../assets/css/main.css"),
    tags$title("Podping-Stats")
  ),
  fluidRow(
    HTML("<h2>&nbsp 'podping-stats.com' site usage stats:</h2>"),
    verbatimTextOutput("podping_info")
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$podping_info <- renderPrint({
    clientData <- dplyr::select(clientDataReport(),date,hash,appName)
    clientData <-rename(clientData,VisitId = hash)
    base::summary(clientData)  
  }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
