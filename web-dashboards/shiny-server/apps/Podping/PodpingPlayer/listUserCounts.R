#!/usr/bin/Rscript
    library(anytime)

    hitCounter <- feather::read_feather("./clientData.feather")

    test <- hitCounter$timestamp[1]
    message(test)

    test <- anytime(as.numeric(test))
    message(test)

    hitCounter$dateTime <- anytime(as.numeric(hitCounter$timestamp))

    # summarize
    tail(hitCounter)
    summary(hitCounter)

    
