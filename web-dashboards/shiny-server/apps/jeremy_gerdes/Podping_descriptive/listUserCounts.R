#!/usr/bin/Rscript
    hitCounter <- feather::read_feather("./clientData.feather")

    # summarize
    tail(hitCounter)
    summary(hitCounter)

