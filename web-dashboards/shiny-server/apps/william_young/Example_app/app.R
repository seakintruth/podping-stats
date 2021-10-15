library(shiny)
library(parallel)
#library(ggplot2)
#licence MIT
max_step_count <- 10^5
max_run_count <- 2000

# Define UI for application that draws
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
                        max = max_run_count,
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
        numSteps <- input$stepNum
        if (input$runNum==1) {
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
            processing_time <- round(proc.time()["elapsed"] - ptm["elapsed"],3)
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
            num_runs <- input$runNum
            # start the clock!
            ptm <- proc.time()
	          run_cores <- future::availableCores()-1
            #create random walk using vectors, a single walk is generated and them plotted using both plot and ggplot
            cl <- makeCluster(run_cores)
            clusterSetRNGStream(cl, iseed = 42)
            cluster_overhead_time <- proc.time()["elapsed"] - ptm["elapsed"]
            ptm <- proc.time()
            distances_traveled <- parLapply(
                cl, 
                1:num_runs, 
                fun=function(i,steps) {
                    Distance = function(v1,v2) {
                      v <- (v2-v1)^2
                      sqrt(v[,1] + v[,2])
                    }
                    theta <- 2*pi*runif(n = steps)
                    x <- c(0, cumsum(cos(theta)))   #cos(theta) creates distance in x for each step, cumsum() creates cumulative sum, then add starting x of 0
                    y <- c(0, cumsum(sin(theta)))   #sin(theta) creates distance in y for each step, cumsum() creates cumulative sum, then add starting y of 0
                    # points_run <- cbind(x,y)
                    # colnames(points_run) <- c("x","y")
                    # points_run                    
		    # This is the total distance traveled this run
                    distanceTraveled <- Distance(
                        cbind(x[1],y[1]),
                         cbind(x[length(x)],y[length(y)])
                    )
                    distanceTraveled <- round(distanceTraveled,3)
                },
                steps=numSteps
            )
            processing_time <- proc.time()["elapsed"] - ptm["elapsed"]
            ptm <- proc.time()
            stopCluster(cl)
            cluster_overhead_time <- cluster_overhead_time +  proc.time()["elapsed"] - ptm["elapsed"]
            summary_text <- paste0("On ",
    	    	  run_cores,
  	  	      " cores ",
		          num_runs, " runs of Random Walk at ",numSteps,
              " steps resulted in : \n",
    	  	    "A minimum distance of ",min(unlist(distances_traveled)),"\n",
    	  	    "A median distance of ",summary(unlist(distances_traveled))["Median"],"\n",
    	  	    "A max distance of ",max(unlist(distances_traveled)),"\n",
    	  	    "in " ,round(processing_time,3),
              " sec, with a cluster overhead time of: ",
        		  round(cluster_overhead_time,3) 
            )

            output$summary <- renderPrint({
                cat(summary_text)
            })
            hist(unlist(distances_traveled))
        }
    })

}

# Run the appsummarylication 
shinyApp(ui = ui, server = server)
