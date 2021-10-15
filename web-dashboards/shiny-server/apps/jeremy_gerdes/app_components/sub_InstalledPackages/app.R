library(shiny)
library(DT)
library(dplyr)
# Loads the funciton hit_counter
source("../../../../assets/R_common/hitCounter.R")

# create_link function is modified from https://stackoverflow.com/a/29637883
create_link <- function(val) {
  sprintf('<a href="%s" target="_blank" class="btn btn-primary">1st link</a>',val)
}
installed_packages <- installed.packages(
  fields=c("Package","Version","Built","Depends","Imports","Suggests","LinkingTo","Enhances","URL")
)[,c("Package","URL","Version","Built","Depends","Imports","Suggests","LinkingTo","Enhances")]
availablePackages=available.packages()[,"Package"]
missed_Packages <- setdiff(as.vector(availablePackages), as.vector(installed_packages[,"Package"]))
total_missed <- length(missed_Packages)
installed_packages<- as.data.frame(installed_packages)
installed_packages$URLs <- installed_packages$URL
installed_packages$URL <- gsub(",.*$","",installed_packages$URL)
installed_packages$Link <- create_link(installed_packages$"URL")
installed_packages$URL <- dplyr::mutate(
  installed_packages[,c("URL","Link")],
  Link = ifelse(URL == "","",Link)
)[,"Link"]

# re-order and select columns
installed_packages <- installed_packages[,c("Package","URL","URLs","Version","Built","Depends","Imports","Suggests","LinkingTo","Enhances")]

ui <- fluidPage(
  fluidPage(
    fluidRow(
      # Fluid Column total width is 12
      column(6,
        verbatimTextOutput("summary")
      ),
      column(4,
        downloadButton("downloadData", "Download")
      ),
      htmlOutput("run_once")
    ),
    fluidRow(
      DT::dataTableOutput("mytable1")
    ),
    fluidRow(
      # Adding a bunch of new lines at the end due to IFRAME hieght issues
      # this is a dirty work around but it works!
      HTML("<br/><br/><br/><br/><br/>")
    ) ,
  )
)

server <- function(input, output,session) {
  output$run_once <- renderText({
    client_query_processed <- hit_counter(session) # nolint
    '<span id=hitcounter></span>'
  })
  # Generate a summary of the dataset ----
  output$summary <- renderPrint({
    total_installed <- length(installed_packages[,"Package"])
    cat(
      total_installed,
      "Packages installed on this server.\n",
      total_missed,"packages available on CRAN have not been installed.")
  })

  output$explain <- renderPrint({
    cat("Explain")
  })
  # pretty Data Tables
  output$mytable1 <- DT::renderDataTable({
    DT::datatable(installed_packages,escape=FALSE)
  }, escape=FALSE)

  output$downloadData <- downloadHandler(
    filename = function() {
      paste0("installed_packages_podping-stats_",format(Sys.time(),"%Y-%m-%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      write.csv(installed_packages, file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)