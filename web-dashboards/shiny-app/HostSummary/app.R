library(shiny)
library(DBI)
library(RPostgres)
library(glue)

authenticate_with_posgtres <- function(){
  # Prompt user if password is not yet set
  if (Sys.getenv("PGPASSWORD") == "") {
    Sys.setenv(PGPASSWORD = readLines(file("~/env/read_all_user_access.txt")) )
  }
  # Set environment variables for pgsql connection
  if (! Sys.getenv("PGHOST") == "127.0.0.1") {
    Sys.setenv(PGHOST = "127.0.0.1")
  }
  if (! Sys.getenv("PGPORT") == "5432") {
    Sys.setenv(PGPORT = "5432")
  }
  if (! Sys.getenv("PGUSER") == "read_all") {
    #Sys.setenv(PGUSER = "postgres")
    Sys.setenv(PGUSER = "read_all")
  }
  if (! Sys.getenv("PGDBNAME") == "plug_play") {
    Sys.setenv(PGDBNAME = "plug_play")
  }
}

dbFetchTable_Podping <- function(table_name){
  # Connect to the default postgres database
  connection <- DBI::dbConnect(RPostgres::Postgres(),dbname=Sys.getenv("PGDBNAME"))
  ptm <- proc.time()
  table_con <- DBI::dbSendQuery(connection,paste0( "SELECT * FROM ",table_name))
  table_results <- dbFetch(table_con)
  DBI::dbClearResult(table_con)
  # Close the connection
  proc.time() - ptm
  DBI::dbDisconnect(connection)
  return(table_results)
}

dbFetchQuery_Podping <- function(query_sql){
  # Connect to the default postgres database
  connection <- DBI::dbConnect(RPostgres::Postgres(),dbname=Sys.getenv("PGDBNAME"))
  table_con <- DBI::dbSendQuery(connection,query_sql)
  table_results <- dbFetch(table_con)
  DBI::dbClearResult(table_con)
  # Close the connection
  DBI::dbDisconnect(connection)
  return(table_results)
}

# When this changes we need to get new data
get_last_block_num <-function(){
  dbFetchQuery_Podping(
    "SELECT block_num FROM custom_json_ops ORDER BY id DESC LIMIT 1;"
  )
}
get_podpings_served <- function(){
  dbFetchQuery_Podping(
    "SELECT count(*) FROM public.podping_urls;"
  )
}
get_host_summary <- function(number_of_days){
  if (! Sys.getenv("PGPASSWORD") == "") {
    #      dbFetchQuery_Podping(
    #        cat(suppressWarnings(
    #          readLines("sql/get_host_summary_prefix.sql_part1")
    #          ))
    #      )
    dbFetchTable_Podping("podping_host_summary_last_day_sub_example")
  }
}

get_url_timestamp <- function(){
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbFetchTable_Podping("podping_url_timestamp")
  }
}

get_url_count_by_day <- function(){
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbFetchTable_Podping("podping_url_count_by_day")
  }
}
get_url_count_by_hour <- function(){
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbFetchTable_Podping("podping_url_count_by_hour")
  }
}
get_url_count_by_minute <- function(){
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbFetchTable_Podping("podping_url_count_by_minute")
  }
}

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../../assets/css/main.css"),
    tags$title("Podping-Stats")
  ),
  fluidRow(
    HTML(
      '<div class="topnav">
                <a class="active" href="https://shiny.podping-stats.com/">Stats</a>
                <a href="https://www.podping-stats.com/index.html">Toot Bot Reports</a>
                <a href="https://www.podping-stats.com/contact.html">Contact</a>
                <a href="https://www.podping-stats.com/about.html">About</a>
       </div>'
    )
  ),
  fluidRow(
    column(12,
      HTML(
        '<h2>
        <a href="https://peakd.com/podcasting2/@podping/overview-and-purpose-of-podpingcloud-and-the-podping-dapp">
          <img src="../../../../assets/images/podping_logo.png" width=50 hight=50 alt="podping logo" /> 
          Podping 
        </a> on 
        <a href="https://hive.io/">
          <img src="../../../../assets/images/hive_logo.png" width=50 hight=50 alt="Hive.io logo"/>
          blockchain 
        </a>
        - Stats: Host Summary 
        </h2>'
      )
    )
  ),
  # Show a plot of the generated distribution
  # Main panel for displaying outputs ----
  fluidRow(
    # Input: Selector for choosing dataset ----
    column(2,
      checkboxInput(
        inputId="chkEnableLiveData",
        label="Enable Live Data Updates", 
        value = FALSE,
        width = NULL
      )  
    ),
    #column(2,
      #selectInput(
        #inputId = "time_frame",
        #label = "Choose a time frame:",
        #choices = c("minutes", "hours", "days","months","years"),
	      #selected = "hours"
      #)
    #),
    #column(2,
      #numericInput(
        #inputId = "time_period",
        #label = "Enter time period",
        #value = "24"
      #)
    #),
    column(6,
      verbatimTextOutput("debugging")
    )
  ),
  fluidRow(
    column(6,
      plotOutput("histoPlot")
    ),
    column(6,
      DT::dataTableOutput("mytable1")
    )
  ),
  fluidRow(
    column(2,
      HTML(
        '<p>&nbsp <br/>
          <a href="https://podcastindex.org/">
            <img src="../../../../assets/images/podcast_index_logo.jpeg" width=150px />
          </a>
        </p>'
      )
    ),
    column(4,
      verbatimTextOutput("podings_served")
    ),
    column(5,
      verbatimTextOutput("summary_info")
    )

  )
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
  pollData <- reactivePoll(450, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the contenT
    valueFunc = function() {
      get_host_summary(1)
    }
  )
  pollLastBlock <- reactivePoll(500, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the contenT
    valueFunc = function() {
      get_last_block_num()
    }
  )
  pollPodPingsServed <- reactivePoll(550, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the contenT
    valueFunc = function() {
      format(round(as.numeric(get_podpings_served()$count), 0), nsmall=0, big.mark=",")       
    }
  )

  output$podings_served <- renderPrint({
    cat(paste0("Podpings Served:",pollPodPingsServed()))
  })

  output$debugging <- renderPrint({
    cat(paste0("Results for the past 24 hours"))
  })
  output$summary_info <- renderPrint({
    cat(paste0("Last block processed:",pollLastBlock()))
  })
  # choose columns to display
  output$mytable1 <- DT::renderDataTable({
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
