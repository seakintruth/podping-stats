library(shiny)
library(DBI)
library(RPostgres)
library(glue)

authenticate_with_postgres <- function() {
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

dbfetch_table_podping <- function(table_name) {
  # Connect to the default postgres database
  connection <- DBI::dbConnect(RPostgres::Postgres(),dbname=Sys.getenv("PGDBNAME"))
  ptm <- proc.time()
  table_con <- DBI::dbSendQuery(connection,paste0( "SELECT * FROM ",table_name))
  table_results <- dbfetch(table_con)
  DBI::dbClearResult(table_con)
  # Close the connection
  proc.time() - ptm
  DBI::dbDisconnect(connection)
  return(table_results)
}

dbfetch_query_podping <- function(query_sql) {
  # Connect to the default postgres database
  connection <- DBI::dbConnect(RPostgres::Postgres(),dbname=Sys.getenv("PGDBNAME"))
  table_con <- DBI::dbSendQuery(connection,query_sql)
  table_results <- dbfetch(table_con)
  DBI::dbClearResult(table_con)
  # Close the connection
  DBI::dbDisconnect(connection)
  return(table_results)
}

get_podpings_served <- function() {
  dbfetch_query_podping(
    "SELECT count(*) FROM public.podping_urls;"
  )
}

# When this changes we need to get new data
get_last_hive_block_num <-function() {
  dbfetch_query_podping(
    "SELECT block_num FROM custom_json_ops ORDER BY id DESC LIMIT 1;"
  )
}

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../../assets/css/main.css"),
    tags$title("Podping-Stats")
  ),
  # Main panel for displaying outputs ----
  fluidRow(
      # Input: Selector for choosing dataset ----
    column(3,
      verbatimTextOutput("debugging")
    ),
    column(3,
      verbatimTextOutput("summary_info")
    )
  ),
  fluidRow(
    HTML(
    '<p>&nbsp <br/>
      <a href="https://podcastindex.org/">
        <img src="../../../../assets/images/podcast_index_logo.jpeg" width=150px />
      </a>
    </p>'
    )
  )  
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
  pollData <- reactivePoll(450, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        get_last_hive_block_num()
      }),
    # This function returns the conteny
    valueFunc = function() {
      get_podpings_served(1)
    }
  )
  output$summary_info <- renderPrint({
    cat(paste0("Podpings Served: ",pollData()))
  }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
