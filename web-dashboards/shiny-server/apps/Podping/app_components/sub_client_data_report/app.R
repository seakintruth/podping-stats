library(shiny)
library(DBI)
library(RPostgres)
library(glue)
library(lubridate)
library(data.table)
#library(ggplot2)
library(dygraphs)
library(xts) # To make the convertion data-frame / xts format
library(tidyr)
# for dev:
#    setwd("/srv/shiny-server/apps/Podping/app_components/sub_client_data_report/")

# [TODO] review streaming data visulizations with plotly
# https://plotly-r.com/linking-views-with-shiny.html#shiny-performance
source("../../../../assets/R_common/hitCounter.R")
source("../../../../assets/R_common/clientDataReport.R")

#load once
clientDataRaw <- clientDataReport()

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
      #HTML("<br/>test<br/>")
      DT::DTOutput("podpingDt")
    )
  ),
  fluidRow(
    column(
      12,
      dygraphOutput("userTimeChart")
    )
  ),
  fluidRow(
    column(
      12,
      dygraphOutput("usageChart")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$userTimeChart <- renderDygraph({
    clientData <- clientDataRaw # getClientData()
    #clientDataCounts <- dt_clientData[,.N,by=.(appName,paste0(lubridate::year(date),lubridate::month(date),lubridate::day(date)))]
    dt_clientData <- data.table::as.data.table(clientData)
    clientDataCounts <- dt_clientData[,.N,by=.(as.Date(date,'%d/%m/%Y'))]
    names(clientDataCounts) <- c("Date","Count")
    clientDataCounts$Count_3day_RollingMean <- zoo::rollmean(
      x = clientDataCounts$Count,k=3,fill=NA
    )
    # xts format:
    don <- xts::xts(x=clientDataCounts, order.by=clientDataCounts$Date)
    # Chart
    p <- dygraph(
      don, 
      main = "Daily Total Page/Component Hits",
      ylab = "Count of Hits",
      group = "hitCountGroup"
    )
    p <- dyRangeSelector(p,dateWindow = c(Sys.Date()-28, Sys.Date()))    
    p
  })
  output$usageChart <- renderDygraph({
    clientData <- clientDataRaw # getClientData()
    #clientDataCounts <- dt_clientData[,.N,by=.(appName,paste0(lubridate::year(date),lubridate::month(date),lubridate::day(date)))]
    dt_clientData <- data.table::as.data.table(clientData)
    clientDataCounts <- dt_clientData[,.N,by=.(appName,as.Date(date,'%d/%m/%Y'))]
    names(clientDataCounts) <- c("App_Name","Date","Count")
    clientDataCounts <- tidyr::pivot_wider(clientDataCounts,names_from="App_Name",values_from ="Count")
    # xts format:
    don <- xts::xts(x=clientDataCounts, order.by=clientDataCounts$Date)
    p <- dygraph(don,
      group = "hitCountGroup"
    )
    p <- dyRangeSelector(p,dateWindow = c(Sys.Date()-28, Sys.Date()))    
    p
  })  
}

# Run the application 
shinyApp(ui = ui, server = server)
