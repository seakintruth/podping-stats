library(shiny)
library(ggplot2)

max_step_count <- 10^6

# Loads the funciton hit_counter
source("../../../../assets/R_common/hitCounter.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "../../../assets/css/main.css")
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
    # User input for run numbers + Summary
    fluidRow(
        column(3,
            sliderInput("stepNum",
                        h3("Random Walk # of steps:"),
                        min = 1,
                        max = max_step_count,
                        value = ceiling( max_step_count/100)),
        )
        ,
        column(3,
            sliderInput("runNum",
                        h3("Number of runs:"),
                        min = 1,
                        max = 1000,
                        value = 1),
        ),
        column(6,
            verbatimTextOutput("summary")
        )
    ),
    fluidRow(
        column(12,plotOutput("randomWalkPlot"))
    )
)

# Define server logic required to draw a plot
server <- function(input, output) {
    output$randomWalkPlot <- renderPlot({
        if (input$runNum==1) {
            #total_step_count <- input$runNum
            numSteps <- input$stepNum
            # start the clock!
            ptm <- proc.time()
            #create random walk using vectors, a single walk is generated and them plotted using both plot and ggplot
            theta <- 2*pi*runif(numSteps)	#create vector of size numSteps holding random angles 0 to 360
            x <- c(0, cumsum(cos(theta)))   #cos(theta) creates distance in x for each step, cumsum() creates cumulative sum, then add starting x of 0
            y <- c(0, cumsum(sin(theta)))   #sin(theta) creates distance in y for each step, cumsum() creates cumulative sum, then add starting y of 0

            Distance = function(v1,v2) {
            v <- (v2-v1)^2
            sqrt(v[,1] + v[,2])
            }
            distanceTraveled <- Distance(
                cbind(x[1],y[1]),
                cbind(x[length(x)],y[length(y)])
            )
            processing_time <- proc.time() - ptm
            ptm <- proc.time()
            summary_text <- paste0("Random Walk of ",numSteps,
                    " steps resulted \nin a final distance traveled of ",
                    round(distanceTraveled,1), "\nin " ,processing_time,
                    " sec"
            )
            output$summary <- renderPrint({
                cat(summary_text)
            })
            #coords <- data.frame(x,y)
            #p <- ggplot(coords,aes(x,y)) + geom_path()
            #print(p)
            #plot using base R
            plot(
                x,
                y,
                xlab=paste0("x"),
                ylab="y",
                main=paste0("Random Walk of ",numSteps,
                    " steps") , 
                type = 'l'
            )
        } else {
            summary_text <- "Multiple Runs not built yet, select one run..."
            output$summary <- renderPrint({
                cat(summary_text)
            })
        }
    })

}

# Run the appsummarylication 
shinyApp(ui = ui, server = server)





