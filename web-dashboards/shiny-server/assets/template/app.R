library(shiny)
# Define server logic for random distribution app ----
server <- function(input, output) {
  # silence is golden
  # Doing nothing here but load the template file...
}

# Create Shiny app ----
shinyApp(ui = htmlTemplate("index.html"), server)
