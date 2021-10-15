summarize_hit_counter <- function() {
    hitCounter <- feather::read_feather("./clientData.feather")

    # summarize
    results <- cat(tail(hitCounter))
    results <- cat(paste0(results,"\n",summary(hitCounter)))
}