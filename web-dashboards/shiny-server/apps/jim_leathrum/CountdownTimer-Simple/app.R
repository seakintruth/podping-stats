library(lubridate)
library(shiny)

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
    titlePanel("Countdown Timer"),
    sidebarLayout(
        sidebarPanel(
            actionButton('start','Start'),
            actionButton('pause','Pause'),
            actionButton('stop','Stop'),
            numericInput('hours','Hours:',value=0,min=0,max=24,step=1),
            numericInput('minutes','Minutes:',value=0,min=0,max=60,step=1),
            numericInput('seconds','Seconds:',value=0,min=0,max=60,step=1)
        ),
        mainPanel(
            textOutput('timeleft'),
            tags$head(
                tags$style(
                    "#timeleft{color: green;
                    font-size: 50px;
                    font-style: italic;
                    }"
                )
            )
        )
    ),
    fluidRow(
        HTML('<div class="caption">
            A working example of a simple Countdown Timer.<br/>
            Contributed by <a href="https://www.odu.edu/directory/people/j/jleathru">
            Dr. Jim Leathrum
            </a>ASSOCIATE PROFESSOR Computational Modeling and Simulation Engineering, 
            Old Dominion University</div>'
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

    # observer that invalidates every second. If timer is active, decrease by one.
    observe({
        invalidateLater(1000, session)
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