library(shiny)
library(DBI)
library(RPostgres)
library(glue)
library(anytime)
library(feather)

# for dev:
#    setwd("/srv/shiny-server/apps/Podping/app_components/sub_client_data_report/")

# [TODO] review streaming data visulizations with plotly
# https://plotly-r.com/linking-views-with-shiny.html#shiny-performance

source("../../../../assets/R_common/clientDataReport.R")

#load once
clientData <- clientDataReport()

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
    column(
      12,
      textOutput("podping_info")
    )
  ),
  fluidRow(
    column(
      12,
      #HTML("<br/>test<br/>")
      DT::DTOutput("podpingDt")
    )
  ),
  fluidRow(
    column(
      12,
      plotOutput("userChart")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

  output$podping_info <- renderText({
    clientData$timestamp <-anytime::anytime(clientData$timestamp)
    clientData$client_query <- dplyr::na_if(clientData$client_query,"")
    siteVisitCount <- dplyr::count(clientData)
    paste0(
      "Site hits: ",
      siteVisitCount
    )
  })

  output$podpingDt <- DT::renderDT({
    clientDataTable <- DT::datatable(
      summary(dplyr::select(clientData,appName)),
      options = list(dom = 't')
    )
  })

  output$userChart <- renderPlot({
    plot(
      x = anytime::anytime(clientData$timestamp),
      y = clientData$appName
    )
  })

}

# Run the application 
shinyApp(ui = ui, server = server)
