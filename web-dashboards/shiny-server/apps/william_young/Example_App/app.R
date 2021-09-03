#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)

#create random walk runs
num_runs <- 30
run_distance <- vector(length = num_runs)
dist <- vector(length = 10)
maximum_steps <- 100
steps <- seq(10, maximum_steps, by = 10)

for ( numSteps in steps) {
    x_walks<- array(dim = c(num_runs, numSteps))
    y_walks <- array(dim = c(num_runs, numSteps))
    for ( i in 1:num_runs) {
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
    dist[numSteps/10] <- mean(run_distance)
}

xrange = max(x_walks) - min(x_walks)
yrange = max(y_walks) - min(y_walks)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Random Walk - Example (slow loops)"),

    # Sidebar with a slider input for run number 
    sidebarLayout(
        sidebarPanel(
            sliderInput("runNum",
                        h3("Run number:"),
                        min = 0,
                        max = num_runs,
                        value = ceiling( num_runs/2)),
            sliderInput("xslider", label = h3("X Range"), 
                        min = min(x_walks)-0.1*xrange, 
                        max = max(x_walks) +0.1*xrange, 
                        value = c(min(x_walks)-0.01*xrange, max(x_walks) +0.01*xrange)),
            sliderInput("yslider", label = h3("Y Range"), 
                        min = min(y_walks)-0.1*yrange, 
                        max = max(y_walks) +0.1*yrange, 
                        value = c(min(y_walks)-0.01*yrange, max(y_walks) +0.01*yrange))
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("randomWalkPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$randomWalkPlot <- renderPlot({
        if (input$runNum > 0) 
        {
            walks <- data.frame("xval" = x_walks[input$runNum,], "yval" = y_walks[input$runNum,])
            
            ggplot(walks, aes(x = xval, y = yval)) + geom_point() + geom_path() +
                xlim(input$xslider[1],input$xslider[2]) +
                ylim(input$yslider[1],input$yslider[2])
        }
        else
        {
            p <- ggplot()
            for (i in 1:num_runs)
            {
                walks <- data.frame("xval" = x_walks[i,], "yval" = y_walks[i,])
                p <- p + geom_path(aes(x = xval, y = yval), data = walks, color = i)
            }
            p <- p + xlim(input$xslider[1],input$xslider[2]) +
                     ylim(input$yslider[1],input$yslider[2])
            p
        }

    })
}

# Run the application 
shinyApp(ui = ui, server = server)
