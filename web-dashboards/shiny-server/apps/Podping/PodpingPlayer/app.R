library(shiny)
library(DBI) # Required by authenticateWithPostgres.R
library(RPostgres) # Required by authenticateWithPostgres.R
library(glue)
library(htmlwidgets)
#library(feather) # Requried by hitCounter.R

#-----------------------------------------------------------------------#
# Ultimately the files sourced here should be a new package             #
# just replace these source calls with a single library('podpingStats') #
#-----------------------------------------------------------------------#
# Loads the funciton hit_counter
source("../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../assets/R_common/authenticateWithPostgres.R")

# create_link function is modified from https://stackoverflow.com/a/29637883
create_link <- function(val) {
  paste0('<a href="',val,'" target="_blank" class="btn btn-primary">',val,'</a>')
}

create_iframe <- function(val){
  paste0('<iframe src="',val,'" height="300" width="100%" title="podpingUrl_',val,'"></iframe>')
}

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "../../../assets/css/main.css"),
    tags$title("Podping-Stats")
  ),
  fluidRow(
    HTML(
      '<div class="topnav">
                <a class="active" href="https://shiny.podping-stats.com/">Stats</a>
                <a href="https://www.podping-stats.com/index.html">Toot Bot Reports</a>
                <a href="https://www.podping-stats.com/contact.html">Contact</a>
                <a href="https://www.podping-stats.com/about.html">About</a>'
    ),
    htmlOutput("run_once"),
    HTML('</div>')
  ),
  fluidRow(
    column(3,
      HTML(
        '<h2>
          <u>Podping Player</u>
        </h2>
	<p>Just a list of links and iframes of last podpings</p>
	'
      )
    ),
    column(9,
      HTML(
        '<h3>
          Analyzing <a href="https://peakd.com/podcasting2/@podping/overview-and-purpose-of-podpingcloud-and-the-podping-dapp">
            <img src="../../../../assets/images/podping_logo.png" width=50 hight=50 alt="podping logo" /> 
            Podping
          </a> on
          <a href="https://hive.io/">
            <img src="../../../../assets/images/hive_logo.png" width=50 hight=50 alt="Hive.io logo"/>
            blockchain
          </a> as envisioned by<span id=podcast_index_logo>
            <a href="https://podcastindex.org/">
              <img src="../../../../assets/images/podcast_index_logo.jpeg" width=150px />
            </a>
          </span>
        </h3>'
      )
    )
  ),
  # Show a plot of the generated distribution
  # Main panel for displaying outputs ----
  fluidRow(
    # Input: Selector for choosing dataset ----
    column(3,
      checkboxInput(
        inputId="chkEnableLiveData",
        label="Enable Live Data Updates (refresh every 3 seconds)", 
        value = FALSE,
        width = NULL
      )  
    ),
    column(3,
    numericInput(
            inputId = "ReturnUrlCount",
            label = "Number of podping urls to display:", 
            value = 10000
        )    
    ),
    column(
      6,
      HTML(
        '<code>The search on this page only searches the timestamp and rss url values (not the contents of the feeds)</code>'
      )
    )
  ),
  fluidRow(
    column(12,
      DT::dataTableOutput("results_table")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session)
    '<span id=hitcounter></span>'
  })

  pollLastPodpingUrls <- reactivePoll(3000, session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
        if (input$chkEnableLiveData) {
          get_last_hive_block_num()
        } else {
          FALSE
        }
      }),
    # This function returns the content
    valueFunc = function() {
      url_list <- dbfetch_query_podping(
        paste0("SELECT bb.timestamp,
                    pp.url,
                    pp.json_ops_id
                  FROM blocks bb,
                    custom_json_ops cc,
                    ( SELECT jo.id AS json_ops_id,
                      json_array_elements_text((jo.op_json ->> 'urls'::text)::json) AS url
                      FROM custom_json_ops jo
                      ORDER BY jo.id DESC
                      FETCH FIRST ",input$ReturnUrlCount," ROWS ONLY
                    ) pp
                  WHERE bb.num = cc.block_num AND cc.id = pp.json_ops_id
                  ORDER BY pp.json_ops_id DESC"
        )
      )
      url_list$url <- paste0(
        create_link(url_list$url),
        "<span>&nbsp&nbsp",url_list$timestamp,"</span><br/>",
        create_iframe(url_list$url)
      )
      url_list_return <- as.data.frame( url_list$url)

      colnames(url_list_return) <- c("Podping Link, Timestamp and Iframe")
      # Return
      url_list_return
    }
  )

  # choose columns to display
  output$results_table <- DT::renderDataTable({
    DT::datatable(
      pollLastPodpingUrls()
    , escape=FALSE)
  }, escape=FALSE)
}
# Run the application 
shinyApp(ui = ui, server = server)
