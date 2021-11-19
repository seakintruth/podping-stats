library(shiny)
library(DBI) # Required by authenticateWithPostgres.R
library(RPostgres) # Required by authenticateWithPostgres.R
library(glue)
library(stringr)
library(shinyTime)

#library(feather) # Requried by hitCounter.R

#-----------------------------------------------------------------------#
# Ultimately the files sourced here should be a new package             #
# just replace these source calls with a single library('podpingStats') #
#-----------------------------------------------------------------------#
# Loads the funciton hit_counter
source("../../../assets/R_common/hitCounter.R")
# Loads authentication, and query functions for postgresql database
source("../../../assets/R_common/authenticateWithPostgres.R")
# Loads podcastindex api query functions
source("../../../assets/R_common/podcastIndexGet.R")

ListenElsewhere <- function(
  playerUrl,
  playerName,
  imgUrl,
  urlIdNumber,
  sep="/",
  suffix=""
){
  glue(
    '<td>',
    '<a class="podcastsubscribe" ',
    'target="_blank" rel="noopener noreferrer" ',
    'href=',
    '"{playerUrl}{sep}{urlIdNumber}{suffix}"',
    '>',
    '<div>',
    '<img class="shadow" loading="lazy" ',
    'alt="{playerName}" ',
    'src="{imgUrl}" ',
    'width="44" height="44"',
    '>',
    '</div>',
    '{playerName}',
    '</a>',
    '</td>', 
    .na=""
  )
}

# create_link function is modified from https://stackoverflow.com/a/29637883
create_url_html <- function(url_val="", strHost="PodcastIndex") {
  errorLoad <- tryCatch(
    {
      feedPayload <- podcast_index_get_by_url(url_val)
    },
    error=function(cond) {
      message(paste("URL does not seem to exist:", url_val))
      message("Here's the original error message:")
      message(cond)
      # Choose a return value in case of error
      return(NA)
    },
    warning=function(cond) {
      message(paste("URL caused a warning:", url_val))
      message("Here's the original warning message:")
      message(cond)
      # Choose a return value in case of warning
      return(NULL)
    },
    finally={
      # NOTE:
      # Here goes everything that should be executed at the end,
      # regardless of success or error.
      message(paste("Processed URL:", url_val))
    }
  )
  
  feedTitle=""
  if(!is.null(feedPayload) & !is.na(feedPayload)){
    if(!is.null(feedPayload$feed$title)){
      feedTitle <-stringr::str_trunc(paste0(
        feedTitle,feedPayload$feed$title
      ),150)
    }
    if(!is.null(feedPayload$feed$categories)){
      feedTitle <- paste(
        feedTitle,stringr::str_trunc(paste0(
          feedPayload$feed$categories,collapse=":"
        ),150),sep=" --- ")
    }
  }
  if(stringr::str_length(feedTitle)==0){
    feedTitle <-url_val
  }
  # prep for building the Iframe
  feedIframe <- ""
  if(!is.null(feedPayload) & !is.na(feedPayload)){
    if(strHost=="PodcastIndex"){
      if(!is.null(feedPayload$feed$id)){
        feedIframe <- paste0("https://podcastindex.org/podcast/",
                             feedPayload$feed$id)
        feedIframeHieght <- 450
      }
    } else if(strHost=="Podnews_Guid"){
      if(!is.null(feedPayload$feed$podcastGuid)){  
        feedIframe <- paste0(
          "https://podnews.net/podcast/",
          feedPayload$feed$podcastGuid
        )
        feedIframeHieght <- 500
      }
    } else if(strHost=="Curiocaster"){
      if(!is.null(feedPayload$feed$podcastGuid)){
        feedIframe <- paste0("https://curiocaster.com/podcast/",
                             feedPayload$feed$podcastGuid)
        feedIframeHieght <- 650
      }
    } else if(strHost=="PartytimeParser"){
      feedIframe <- paste0(
        "https://partytime.hirsch.dev/?url=",
        url_val
      )
      feedIframeHieght <- 380
    } else if(strHost=="PodcastAddict"){
      feedIframe <- paste0(
        "https://podcastaddict.com/feed/",
        utils::URLencode(url_val,reserved=TRUE)
      )
      feedIframeHieght <- 380
  } 
  # build the iframe
  if(strHost=="None" | stringr::str_length(feedIframe) == 0){
    feedIframe <- ""
  } else { # none
    feedIframe <- glue(
      '<iframe ',
      'loading="lazy"',
      'src="{feedIframe}" ',
      'height="{feedIframeHieght}" ',
      'width="95%" ',
      'title="{feedTitle}"',
      '>',
      '</iframe>', 
    )
  }
}

  feedListenElsewhere <- ""
if(!is.null(feedPayload) & !is.na(feedPayload)){
  # Build the html for the Listen elsewhere: section
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://podcastindex.org/podcast",
      "Podcast Index",
      "../../../assets/images/podcast_player_icons/podcast-index.svg",
      feedPayload$feed$id
    )
  )
  if(!is.null(feedPayload$feed$id)){
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://podnews.net/podcast",
        "Podnews",
        "../../../assets/images/podcast_player_icons/podnews-net-favicon.svg",
        feedPayload$feed$podcastGuid,
        "/"
      )
    )
  }
  if(!is.null(feedPayload$feed$podcastGuid)){
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://curiocaster.com/podcast",
        "Curiocaster",
        "../../../assets/images/podcast_player_icons/curiocaster.jpg",
        feedPayload$feed$podcastGuid
      )
    )
  }
    feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://podcastaddict.com/feed",
      "Podcast Addict",
      "../../../assets/images/podcast_player_icons/podcast-addict.svg",
      utils::URLencode(url_val,reserved=TRUE),
      sep="/"
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://player.fm/subscribe?id",
      "Player FM",
      "../../../assets/images/podcast_player_icons/player-fm.svg",
      url_val,
      sep="="
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "",
      "RSS feed",
      "../../../assets/images/podcast_player_icons/rss.svg",
      url_val,
      sep=""
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://subscribebyemail.com",
      "Subscribe<br/> by Email",
      "../../../assets/images/podcast_player_icons/sube.svg",
      stringr::str_replace(
        stringr::str_replace(
        url_val,
          "https://",""
        ),"http://",""
      ),
      sep="/"
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://podstation.github.io/subscribe-ext",
      "podStation",
      "../../../assets/images/podcast_player_icons/podstation.svg",
      utils::URLencode(url_val,reserved=TRUE),
      sep="/?feedUrl="
    )
  )

  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://podhero.com/podcast/feed",
      "Podhero",
      "../../../assets/images/podcast_player_icons/podhero.svg",
      utils::URLencode(url_val,reserved=TRUE),
      sep="/"
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "http://radiopublic.com",
      "Radio Public",
      "../../../assets/images/podcast_player_icons/radiopublic.svg",
      utils::URLencode(url_val,reserved=TRUE),
      sep="/"
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://podcasts.google.com/feed",
      "Google Podcasts",
      "../../../assets/images/podcast_player_icons/google-podcasts.svg",
      base64enc::base64encode(charToRaw(url_val)),
      sep="/"
    )
  )
  feedListenElsewhere <- paste0(
    feedListenElsewhere, ListenElsewhere(
      "https://subscribeonandroid.com",
      "Subscribe on Android",
      "../../../assets/images/podcast_player_icons/suba.svg",
      url_val,
      sep="/"
    )
  )
#<a class="podcastsubscribe" rel="nofollow" href="/feeds.buzzsprout.com/1585531.rss"><div><img class="shadow" loading="lazy" alt="Subscribe on Android" src="https://podnews.net/static/svg/suba.svg" width="44" height="44"></div>Subscribe on Android</a>div><img class="shadow" loading="lazy" alt="Subscribe on Android" src="https://podnews.net/static/svg/suba.svg" width="44" height="44"></div>
  if(!is.null(feedPayload$feed$itunesId)){
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://web.podfriend.com/podcast",
        "Podfriend",
        "../../../assets/images/podcast_player_icons/podfriend.svg",
        feedPayload$feed$itunesId
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "http://castbox.fm/vic",
        "Castbox",
        "../../../assets/images/podcast_player_icons/castbox.svg",
        feedPayload$feed$itunesId,
        sep="/",suffix="?ref=shiny.podping-stats.com"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://pca.st/itunes",
        "Pocket Casts",
        "../../../assets/images/podcast_player_icons/pocketcasts.svg",
        feedPayload$feed$itunesId,
        sep="/"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://app.podcastguru.io/podcast",
        "Podcast Guru",
        "../../../assets/images/podcast_player_icons/podcast_guru.svg",
        feedPayload$feed$itunesId,
        sep="/"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://www.podbean.com/itunes",
        "Podbean",
        "../../../assets/images/podcast_player_icons/podbean.svg",
        feedPayload$feed$itunesId,
        sep="/"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://overcast.fm",
        "Overcast (iOS)",
        "../../../assets/images/podcast_player_icons/overcast.svg",
        feedPayload$feed$itunesId,
        sep="/itunes"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://podcasts.apple.com/us/podcast/feed",
        "Apple iTunes",
        "../../../assets/images/podcast_player_icons/itunes.svg",
        feedPayload$feed$itunesId,
        sep="/id"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://castro.fm/itunes",
        "Castro (iOS)",
        "../../../assets/images/podcast_player_icons/castro.svg",
        feedPayload$feed$itunesId,
        sep="/"
      )
    )
    feedListenElsewhere <- paste0(
      feedListenElsewhere, ListenElsewhere(
        "https://sonnet.fm/p",
        "Sonnet",
        "../../../assets/images/podcast_player_icons/sonnet.svg",
        feedPayload$feed$itunesId,
        sep="/"
      )
    )
#<a class="podcastsubscribe" rel="nofollow" href="
#https://sonnet.fm/p/1547140545"><div><img class="shadow" loading="lazy" alt="Sonnet" src="https://podnews.net/static/svg/sonnet.svg" width="44" height="44"></div>Sonnet</a>

  }
} 

results=""
errorWrite <- tryCatch(
  {
    results <- glue(
      '<table id="table_podplayer_title"><tr>',
      '<td>',
      '<a href="{url_val}" target="_blank" class="btn btn-primary">',
      '{feedTitle}</a>',
      '</td>',
      '</tr></table>',
      '<table id="table_podplayer_listenelsewhere"><tr>',
      '{feedListenElsewhere}',
      '</tr></table>{feedIframe}',
      .na=""
    )
  },
  error=function(cond) {
    message(paste("URL does not seem to exist:", url_val))
    message("Here's the original error message:")
    message(cond)
    # Choose a return value in case of error
    return(NA)
  },
  warning=function(cond) {
    message(paste("URL caused a warning:", url_val))
    message("Here's the original warning message:")
    message(cond)
    # Choose a return value in case of warning
    return(NULL)
  },
  finally={
    # NOTE:
    # Here goes everything that should be executed at the end,
    # regardless of success or error.
    message(paste("Processed URL:", url_val))
  }
)
# Return results
results
}

# Define UI for application
ui <- fluidPage( 
  tags$head(
    tags$link(rel="apple-touch-icon",href="/apple-touch-icon.png?v=1",sizes="180x180"),
    tags$link(rel="icon",type="image/png",sizes="32x32",href="/favicon-32x32.png?v=1"),
    tags$link(rel="icon", type="image/png", sizes="16x16",href="/favicon-16x16.png?v=1"),
    tags$link(rel="manifest", href="/site.webmanifest?v=1"),
    tags$link(rel="mask-icon", href="/safari-pinned-tab.svg?v=1",color="#5bbad5"),
    tags$link(rel="shortcut icon", href="/favicon.ico?v=1"),
    tags$meta(name="msapplication-TileColor", content="#da532c"),
    tags$meta(name="theme-color", content="#ffffff"),
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
             paste0(
               '<h2>',
               '<u>Podping Player</u>',
               '</h2>',
               '<p>A list of the most recent podping feed upates',
               '<br/>',
               '<iframe ',
               'loading="lazy"',
               'frameBorder="0"',
               'src="../app_components/sub_podpings_served/" ',
               'height="25" ',
               'width="100%" ',
               'title="All Time Podpings Served"',
               '>',
               '</iframe>',
               '</p>'
             )
           )
    ),
    column(9,
           HTML(
             '<h3>
          Analyzing <a href="https://peakd.com/podcasting2/@podping/overview-and-purpose-of-podpingcloud-and-the-podping-dapp">
            <img src="../../../assets/images/podping_logo.png" width=50 hight=50 alt="podping logo" /> 
            Podping
          </a> on
          <a href="https://hive.io/">
            <img src="../../../assets/images/hive_logo.png" width=50 hight=50 alt="Hive.io logo"/>
            blockchain
          </a> as envisioned by<span id=podcast_index_logo>
            <a href="https://podcastindex.org/">
              <img src="../../../assets/images/podcast_index_logo.jpeg" width=150px />
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
    column(2,
           selectInput(
             inputId = "SelectedHost",
             label = "Select Player/Reviewer:",
             choices = c(
               "Podcast Index" = "PodcastIndex",
               "Curiocaster" = "Curiocaster",
               "Podcast Addict"="PodcastAddict",
               "Podnews" = "Podnews_Guid",
               "🎉🕙PartytimeParser" = "PartytimeParser",
               "None" = "None"
             ),
             selected = "PodcastIndex"
           )
    ),
    column(2,
           numericInput(
             inputId = "ReturnUrlCount",
             label = "Number of feeds (max 30)", 
             value = 5,
             min = 1,
             max = 30
           )    
    ),
    column(2,
           # Using the default time 00:00:00
           timeInput("time1", "Starting at local timestamp:", value = Sys.time())
    ),
    column(2,
           actionButton("to_current_time", "Current time")
    ),
    column(2,
           checkboxInput(
             inputId="chkEnableLiveData",
             label="Enable Live Data Updates (refresh every 3 seconds)", 
             value = FALSE,
             width = NULL)
    ),
  ),
  fluidRow(
    column(8,
           htmlOutput("time_summary")
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
    paste0('<span id=hitcounter>', client_query_processed, '</span>')
  })
  observeEvent(input$to_current_time, {
    updateTimeInput(session, "time1", value = Sys.time())
  })
  output$time_summary <- renderText({
    glue(
      input$time1
    )
  })
   # each user/session? polls randomly between .25 and .5 seconds
  pollLastPodpingUrls <- reactivePoll(
    sample(250:500,1 , replace=T),
    session,
    # This function returns the last block that was processed and updates if modified
    checkFunc = function() ({
      if (input$chkEnableLiveData) {
        updateTimeInput(session, "time1", value = Sys.time())
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
      
      url_list_html <-mapply(FUN=create_url_html,url_list$url,strHost=input$SelectedHost)
      url_list_return <- as.data.frame(url_list_html)
      colnames(url_list_return) <- c(
        paste0(
          "Title --- Cagetories/ Listen Elsewhere / Player { Most Recent Feed Timestamp :  ",max(url_list$timestamp)," UTC }"
        )
      )
      # Return
      url_list_return
    }
  )
  
  # choose columns to display
  output$results_table <- DT::renderDataTable({
    DT::datatable(
      pollLastPodpingUrls(),
      rownames=FALSE,
      options = list(dom = 't'),
      escape=FALSE
    )
  }, escape=FALSE)
}

# Run the application 
shinyApp(ui = ui, server = server)
