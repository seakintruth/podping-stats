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

# When this changes we need to get new data
get_last_hive_block_num <-function() {
  dbfetch_query_podping(
    "SELECT block_num FROM custom_json_ops ORDER BY id DESC LIMIT 1;"
  )
}

get_host_summary <- function(number_of_days) {
  if (! Sys.getenv("PGPASSWORD") == "") {
    #      dbfetch_query_podping(
    #        cat(suppressWarnings(
    #          readLines("sql/get_host_summary_prefix.sql_part1")
    #          ))
    #      )
    dbfetch_table_podping("podping_host_summary_last_day_sub_example")
  }
}

get_url_timestamp <- function() {
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbfetch_table_podping("podping_url_timestamp")
  }
}

get_url_count_by_day <- function() {
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbfetch_table_podping("podping_url_count_by_day")
  }
}
get_url_count_by_hour <- function() {
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbfetch_table_podping("podping_url_count_by_hour")
  }
}
get_url_count_by_minute <- function() {
  if (! Sys.getenv("PGPASSWORD") == "") {
    dbfetch_table_podping("podping_url_count_by_minute")
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
  # Application title
  fluidRow(column(9,HTML(
    '<h2>
     <a href="https://peakd.com/podcasting2/@podping/overview-and-purpose-of-podpingcloud-and-the-podping-dapp">
       <img src="../../../../assets/images/podping_logo.png" width=50 hight=50 alt="podping logo" /> 
       Podping 
    </a> on 
    <a href="https://hive.io/">
       <img src="../../../../assets/images/hive_logo.png" width=50 hight=50 alt="Hive.io logo"/>
       blockchain 
     </a>
     </h2>'
  )), column(3,HTML("<!-- live refresh checkbox here -->"))
  ),
  fluidRow(HTML("<h1>See Toot Bot Reports for now ... </h1>")),
  # Show a plot of the generated distribution
  # Main panel for displaying outputs ----
  fluidRow(
      # Input: Selector for choosing dataset ----
    column(3,
      selectInput(
        inputId = "time_frame",
        label = "Choose a time frame:",
        choices = c("minutes", "hours", "days","months","years"),
	selected = "hours"
      )
    ),
    column(3,
      numericInput(
        inputId = "time_period",
        label = "Enter time period",
        value = "24"
      )
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


}

# Run the application 
shinyApp(ui = ui, server = server)
