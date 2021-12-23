
# A non-visible local client data store, for debugging
hit_counter <- function(session) {
  handle_client_reactive_value <- function(session) {
    query <- shiny::parseQueryString(session$clientData$url_search)
    # Return a string with key-value pairs
    query <- paste(names(query), query, sep = "=", collapse=", ")
    query <- data.frame(
      timestamp = format(Sys.time(),"%s"),
      client_query = query,
      hash = session$clientData$url_hash_initial
    )
  }
  if (file.exists("clientData.feather")) {
    hit_attempt <- ""
    hit_attempt <- try ({
      client_data <- feather::read_feather(path="clientData.feather")
      session_data <- handle_client_reactive_value(session)
      client_data  <- rbind(client_data,session_data)
    })
    if (class(hit_attempt) == "try-error") {
      client_data  <-  handle_client_reactive_value(session)
    }
  } else {
      client_data  <-  handle_client_reactive_value(session)
  }
  feather::write_feather(as.data.frame(client_data),path ="clientData.feather")  
  #session$userData$client_data$client_query 
  # Stored data in userData environment, returning TRUE
  TRUE
}