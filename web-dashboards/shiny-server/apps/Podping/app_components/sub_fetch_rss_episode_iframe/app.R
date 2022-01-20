library(shiny)
library(DT)
library(remotes)
#library(tidyRSS)
# tidyRSS with podcast 2.0 namespace updates
remotes::install_github("seakintruth/tidyrss")
library(tidyRSS)

#get_tidy_rss_feed <- function(feed_url,session){
  
#}

# Define UI for application
ui <- fluidPage(
  fluidRow(
    column(12,
     htmlOutput("metadata")
    )
  ),
  fluidRow(
    column(12,
      DT::dataTableOutput("results_table")
    )
  ),
  fluidRow(
    column(12,
      DT::dataTableOutput("results_all")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # choose columns to display
  output$metadata <- renderText({
    query <- parseQueryString(session$clientData$url_search)
    feed_url <- query[["feedUrl"]]
    feed <- tidyfeed(feed_url,clean_tags = FALSE,list = TRUE)
    feedTitle <-  unique(
      as.data.frame(
        feed
      )[c("meta.feed_title","meta.feed_description","meta.feed_link")]
    )
#    titleLink
    paste0(
      "<h2><a href='",feedTitle["meta.feed_link"],"'>",feedTitle["meta.feed_title"], "</a></h2>",
      "<p>",feedTitle["meta.feed_description"],"</p>"
    )
  })

  output$results_table <- DT::renderDataTable({
    query <- parseQueryString(session$clientData$url_search)
    feed_url <- query[["feedUrl"]]
    feed <- tidyfeed(feed_url,clean_tags = FALSE,list = TRUE)
    feedTable <- as.data.frame(
        feed
      )
    feedTable$DisplayTitle <- paste0("<a href=",feedTable[["entries.item_link"]],">",feedTable[["entries.item_title"]],"</a>")
    feedTable <- feedTable[c("entries.item_pub_date","DisplayTitle","entries.item_description")]
    
    #Rename columns
    names(feedTable) <- c("Publish Date","Title","Description")
    # names(feedTable)[names(feedTable) == "entries.description"] <- "Description"
    # Return
    DT::datatable(
      head(feedTable,10),
      escape=FALSE, 
      options = list(dom = 'tip')
    )
  })

  output$results_all <- DT::renderDataTable({
    query <- parseQueryString(session$clientData$url_search)
    feed_url <- query[["feedUrl"]]
    feed <- tidyfeed(feed_url,clean_tags = FALSE,list = TRUE)
    feedTable <- as.data.frame(
        feed)
    
    DT::datatable(
      head(feedTable,10),
      escape=FALSE, 
      options = list(dom = 'tip')
    )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
