rm(list=ls())
setwd('c:/kaggle/lvCleaned')
source('code/fe_func.R')

library(data.table)

# build new scenario dataset
pop <- fread('data/fe.base.csv',stringsAsFactors = T)
pop[,ID:=as.character(ID)]
scenario <- 'simple'
fold <- 1
if (T) {
  for (fold in 0:max(pop$folds)) {
    #fullDF <- df
    cols <- 1:dim(pop)[2]
    fullDF <- pop[,.SD,.SDcols=cols]
    
    # for factors create stats
    factDist <- factDistCreate(fullDF[folds != fold & !is.na(TARGET),])
    
    # target avg calc based on factor stats
    fullDF <- factDistApply(fullDF,factDist,minCatNr = 10, minCount = 15)
    
    fwrite(fullDF, paste('data/fe',scenario,fold,'csv',sep='.'))
    
  }
}

