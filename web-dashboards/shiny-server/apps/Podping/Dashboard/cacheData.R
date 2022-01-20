library(feather)
source("../../../assets/R_common/authenticateWithPostgres.R")

createPodpingCacheFile <- function(fReturnData=TRUE){
  # Load all the data globally, once, takes roughly 2 seconds per million records
  data_return <- dbfetch_query_podping(
    "SELECT * FROM podping_url_timestamp"
  )
  feather::write_feather(data_return,"podping_data_cache.feather")
  if (fReturnData){
    data_return
  } else {
    NULL
  }
}