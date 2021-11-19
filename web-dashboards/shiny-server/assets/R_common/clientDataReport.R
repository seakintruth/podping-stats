clientDataReport <- function(){ 
  #dplyr::summarise(clientDataReport())
  
  #dev testing stuff
  clientDataFiles <- list.files(
    path="/srv/shiny-server",
    pattern="clientData.feather", 
    full.names=TRUE,
    recursive=TRUE
  )
  
  loadFeatherData <- function(filePath)({
    data <- feather::read_feather(filePath)
    data <- tibble::add_column(data,filePath) 
    data <- tibble::add_column(data,stringr::str_split_fixed(filePath,"/",stringr::str_count(filePath,"/")+1)[str_count(filePath,"/")]) 
    names(data)[4] <- "path"
    names(data)[5] <- "appName"
    data
  })
  
  clientData <- lapply(clientDataFiles,FUN=loadFeatherData)
  # Merge all the results togeather
  clientData = Reduce(function(...) merge(..., all=T), clientData)
  clientData$timestamp <- as.numeric(clientData$timestamp)
  clientData$date <- anytime::anytime(clientData$timestamp)
  clientData$appName <- as.factor(clientData$appName)

  #return
  clientData
}
