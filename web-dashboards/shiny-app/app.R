# Install requires these libraries (install as root, or shiny user)
#!/usr/bin/env Rscript
# if (!require("pacman")) install.packages("pacman")
# pacman::p_load(DBI,RPostgres,dplyr,forecast, ggplot2, TSA, TTR,Metrics)
library(DBI)
if ( require(RPostgres) ){
    fReadDataFromFeather <- TRUE
} else {
    fReadDataFromFeather <- FALSE
}
library(dplyr)
library(forecast)
library(ggplot2)
library(TSA)
library(TTR)
library(Metrics)
library(feather)

if (fReadDataFromFeather){


} else {

    # Set environment variables for pgsql connection
    if (! Sys.getenv("PGHOST") == "127.0.0.1") {
    Sys.setenv(PGHOST = "127.0.0.1")
    }
    if (! Sys.getenv("PGPORT") == "5432") {
    Sys.setenv(PGPORT = "5432")
    }
    if (! Sys.getenv("PGUSER") == "postgres") {
    Sys.setenv(PGUSER = "postgres")
    }
    if (! Sys.getenv("PGDBNAME") == "plug_play") {
    Sys.setenv(PGDBNAME = "plug_play")
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

    # start the clock!
    ptm <- proc.time()

    # Query and fetch data
    # user  system elapsed 
    # 0.002   0.000   0.002 

    # The blocks and custom_json_ops tables contain all the data
    # From timing tests, it's much faster to let postgresql views
    # handle the queries to combine and filter, alternatively could
    # pass the sql directly during the Fetch process.
    # The following timings are for 66 days of data 
    # on a modern machine as of 2021/07/22 during a second fetch call
    # --------------------------
    # hive_blocks <- dbFetchTable_Podping("blocks")
    # user  system elapsed 
    # 2.293   0.080   2.374 
    # custom_json_op <- dbFetchTable_Podping("custom_json_ops")
    # proc.time() - ptm
    # user  system elapsed 
    # 0.413   0.024   0.440 
    # --------------------------
    # podping_urls <- dbFetchTable_Podping("podping_urls")
    # user  system elapsed 
    # 0.532   0.035   0.558 
    #  SELECT jo.id AS json_ops_id,
    #  json_array_elements_text((jo.op_json ->> 'urls'::text)::json) AS url
    #  FROM custom_json_ops jo;
    # --------------------------
    url_timestamp <- dbFetchTable_Podping("podping_url_timestamp")
    # user  system elapsed 
    # 1.273   0.053   2.334 
    # --------------------------
    host_summay <- dbFetchQuery_Podping("SELECT * FROM podping_host_summary WHERE count > 2")
    # user  system elapsed 
    # 0.004   0.000   2.745 
    # --------------------------
    ptm <- proc.time()
    url_count_by_day <- dbFetchTable_Podping("podping_url_count_by_day")
    proc.time() - ptm
    # user  system elapsed 
    # 0.005   0.000   0.794 
    # --------------------------
    url_count_by_hour <- dbFetchTable_Podping("podping_url_count_by_hour")
    # user  system elapsed 
    # 0.005   0.003   0.801 
    # --------------------------
    url_count_by_minute <- dbFetchTable_Podping("podping_url_count_by_minute")
    # user  system elapsed 
    # 0.054   0.007   0.882 

}



ui <- fluidPage(
    titlePanel("Hive.io Block Chain Podping Stats"),
    sidebarLayout(
        sidebarPanel(
            if (Sys.getenv("PGPASSWORD") == "") {
                passwordInput("password", "Enter the postgress user password:"),
            },
            actionButton("go", "Go"),
            verbatimTextOutput("value")
            numericInput('hours','Hours:',value=0,min=0,max=24,step=1),
            numericInput('minutes','Minutes:',value=0,min=0,max=60,step=1),
            numericInput('seconds','Seconds:',value=0,min=0,max=60,step=1)
        ),
        mainPanel(
            textOutput('podping_summary'),
            tags$head(tags$style("#timeleft{color: green;
                                 font-size: 50px;
                                 font-style: italic;
                                 }"
            )
            )
        )
    )
)

server <- function(input, output, session) {
    
    # Initialize the timer, 0 seconds, not active.
     timer <- reactiveVal(0)
     active <- reactiveVal(FALSE)

    # Output the time left.
     span(textOutput("timeleft"))
     output$timeleft <- renderText({
         paste("Time left: ", seconds_to_period(timer()))
     })

    # observer that invalidates every 3 seconds. If timer is active, decrease by one.
    observe({
        invalidateLater(3000, session)
        isolate({
            if(active())
            {
                timer(timer()-1)
                if(timer()<1)
                {
                    active(FALSE)
                    showModal(modalDialog(
                        title = "Important message",
                        "Countdown completed!"
                    ))
                }
            }
        })
    })

    # observers for actionbuttons
    observeEvent(input$start, {active(TRUE); timer(input$hours*60*60 + input$minutes*60 + input$seconds)})
    observeEvent(input$pause, 
                {
                    if (active() == TRUE) {
                        active(FALSE)
                    }
                    else {
                        active(TRUE)
                    }
                }
                )
    observeEvent(input$stop, 
                 {
                     active(FALSE);
                     timer(0)
                })
}

shinyApp(ui, server)