library(reticulate)
# start the clock!
pocessing_start_time <- proc.time()
use_condaenv(
    conda_list()[[1]][1],
     required = TRUE
)
if (exists("reticulate_conda_load_time")) {
    reticulate_conda_load_time <-
        reticulate_conda_load_time + proc.time() - pocessing_start_time
} else {
    reticulate_conda_load_time <- proc.time() - pocessing_start_time
}

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
                <a class="active"
                    href="https://shiny.podping-stats.com/">Stats</a>
                <a href="https://www.podping-stats.com/index.html">
                    Toot Bot Reports</a>
                <a href="https://www.podping-stats.com/contact.html">Contact</a>
                <a href="https://www.podping-stats.com/about.html">About</a>
            </div>'
        )
    ),
    fluidRow(
        column(12, HTML(paste0(
            "<div id='Description'>
                <h1>Proof of concept</h1>
                <p>This demonstrates that you can launch an
                anaconda python environment from a shiny app.</br>
                Be aware as this method calls a common environment,
                so only one user at a time can run the python portion
                of this page at a time.</br>
                This is only obvious if each user is running a long
                python process, as the others have to wait for it to
                complete.</p>",
                "<h2>Loading the conda environment took ",
                round(sum(reticulate_conda_load_time), 3), " seconds </h2>
            </div>"
        )))
    ),
    fluidRow(
        column(12, HTML(
            '<a href="http://www.rosettacode.org/wiki/fast_fourier_transform">
                Code snipets for FFT are GNU Free Documentation License 1.2
                from rosettacode.org/wiki/fast_fourier_transform
            </a>'
        ))
    ),
    fluidRow(
        column(12,
            numericInput(
                "obs",
                "Entert the number of randon digits
                to calculate, min=100 max=10^6",
                10000
            )
        )
    ),
    # User input for run numbers + Summary
    fluidRow(
        column(12, HTML("&nbsp;&nbsp;R Fast Fourier transform:"))
     ),
    fluidRow(
       verbatimTextOutput("fast_fourier_transform")
    ),
    fluidRow(
        column(12, HTML("<hr/>&nbsp;&nbsp;Python Fast Fourier transform:"))
    ),
    fluidRow(
       verbatimTextOutput("fast_fourier_transform_py")
    )
)

# Define server logic required
server <- function(input, output) {
    output$fast_fourier_transform <- renderPrint({
        if (input$obs > 10^6) {
            num_observations <- 10^6
        } else if (input$obs < 100) {
            num_observations <- 100
        } else if (is.numeric(input$obs)) {
            num_observations <- input$obs
        } else {
            num_observations <- 100
        }
        dataset_array <- (round(runif(num_observations, min=0, max=1), ))
        pocessing_start_time_r <- proc.time()
        text_output <- paste(fft(dataset_array)[1:5], collapse=" ")
        pocessing_time_r <- proc.time() - pocessing_start_time_r
        cat(paste0(
            paste(dataset_array[1:60],collapse=" "),"...\n",
            text_output, "...\ntook ",
            sum(pocessing_time_r)," seconds to calculate ",
            length(dataset_array)," numbers"
        ))
    })
    output$fast_fourier_transform_py <- renderPrint({
        if (input$obs > 10^6) {
            num_observations <- 10^6
        } else if (input$obs<100) {
            num_observations <- 100
        } else if (is.numeric(input$obs)) {
            num_observations <- input$obs
        } else {
            num_observations <- 100
        }
        dataset_array <- (round(runif(num_observations,min=0,max=1),0))
        pocessing_start_time_py <- proc.time()
        py_run_string("from numpy.fft import fft") # nolint
        py_run_string("from numpy import array") # nolint # nolint
        py$a <- r_to_py(dataset_array) # nolint
        py_run_string("x = ( ' '.join('%5.3f' % abs(f) for f in fft(a)) )") # nolint
        pocessing_time_py <- proc.time() - pocessing_start_time_py
        cat(paste0(
            paste(dataset_array[1:60],collapse=" "),"...\n",
            substr(py$x,1,140),"...\ntook ",
            sum(pocessing_time_py)," seconds to calculate ",
            length(dataset_array)," numbers"
        ))
    })
}

# Run the appsummarylication 
shinyApp(ui = ui, server = server)