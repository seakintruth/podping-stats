library(shiny)
library(ggplot2)

# Loads the funciton hit_counter
source("../../../assets/R_common/hitCounter.R")
max_num_runs <- 30
# Define UI for application that draws a histogram
ui <- fluidPage(
    tags$head(
        tags$link(
            rel = "stylesheet",
            type = "text/css",
            href = "../../../assets/css/main.css"
        )
    ),
    fluidRow(
        HTML(
            '<div class="topnav">
                <a class="active" href="../../../" target="_blank">Home</a>
                <a href="../../">Apps by Authors</a>
                <a href="../">Up</a>
            </div>'
        )
    ),
    # Application title
    titlePanel("Random Walk"),
    # Sidebar with a slider input for run number
    sidebarLayout(
        sidebarPanel(
            sliderInput(
                "runNum",
                h3("Run number:"),
                min = 1,
                max = max_num_runs,
                value = ceiling(max_num_runs / 2)
            ),
            sliderInput(
                "stepNum",
                h3("Step number:"),
                min = 1,
                max = max_num_runs * 50,
                value = ceiling(max_num_runs * 50 / 2)
            )
        ),
        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("random_walk_plot")
        )
    ),
    fluidRow(
        htmlOutput("run_once")
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    output$run_once <- renderText({
        client_query_processed <- hit_counter(session) # nolint
        "<span id=hitcounter>$nbsp</span>"
    })
    output$random_walk_plot <- renderPlot({
        num_runs <- input$runNum
        num_input_steps <- input$stepNum
        run_distance <- vector(length = num_runs)
        dist <- vector(length = 10)
        maximum_steps <- num_input_steps
        steps <- seq(10, maximum_steps, by = 10)
        walks <- data.frame()
        for (numSteps in steps) {
            x_walks <- array(dim = c(num_runs, numSteps))
            y_walks <- array(dim = c(num_runs, numSteps))
            for (i in 1:num_runs) {
                x_walks[i][1] <- y_walks[i][1] <- 0
                for (j in 2:numSteps) {
                    angle <- runif(1) * 2 * pi
                    deltax <- cos(angle)
                    deltay <- sin(angle)
                    x_walks[i,j] <- x_walks[i,j-1] + deltax
                    y_walks[i,j] <- y_walks[i,j-1] + deltay
                }
                run_distance[i] <- sqrt(x_walks[i,numSteps]*x_walks[i,numSteps] + y_walks[i,numSteps]*y_walks[i,numSteps])
            }
            dist <- mean(run_distance)
        }
        walks <- data.frame("xval" = x_walks[num_runs,], "yval" = y_walks[num_runs,])
        plot(
            walks$xval,
            walks$yval,
            xlab=paste0("x"),
            ylab="y",
            main=paste0("Last Random Walk of ",numSteps,
                " steps") , 
            type = 'l',
            sub=paste0("Start to end distance of ", dist)
        )
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
