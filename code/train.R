rm(list=ls())
setwd('c:/kaggle/lvCleaned')
source('code/fe_func.R')

library(data.table)
library(caret)
library(stringi)
library(lubridate)

# model for each folds
scenario <- 'simple'
fold <- 1
pop <- fread('data/fe.base.csv',stringsAsFactors = T) 
#table(sapply(pop,class))

res <- data.table()
mainTeInd <- which(is.na(pop$TARGET))
foldSize <- 5
train_metric = 'rmse'
target <- pop$TARGET

OOFPred <- rep(0,dim(pop)[1])
for (fold in 1:foldSize) {
  fullDF <- fread(paste('data/fe',scenario,fold,'csv',sep='.'),stringsAsFactors = T)
  table(sapply(fullDF,class))

  trInd <- which(fold != fullDF$folds & !is.na(fullDF$TARGET))
  teInd <- which(fold == fullDF$folds)
  set.seed(10)
  ind <- createDataPartition(fullDF$TARGET[trInd],p=0.9,list=F)
  valInd <- trInd[-ind]
  trInd <- trInd[ind]

  # define cols as input for the model : lots of things excluded
  cols <- 1:dim(fullDF)[2]
  cols <- setdiff(cols,which(sapply(fullDF,class) == 'factor'))
  cols <- setdiff(cols, which(names(fullDF) %in% c('ID','TARGET','folds')))
  cols <- setdiff(cols, which(names(fullDF) %in% c('sq.min.Date','sq.max.Date','sq.sd.Date')))
  cols <- setdiff(cols, which(names(fullDF) %in% c('sq.sum.Date','sq.mean.Date')))
  cols <- setdiff(cols, grep('^sq.sd',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.min',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.max',names(fullDF)))

  cols <- setdiff(cols, grep('^sq.day_transaction',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.day_transaction',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.Month',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.Month',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.type',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.type',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.zone',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.zone',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.country',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.country',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.name',names(fullDF)))
  cols <- setdiff(cols, grep('^sq.mean.name',names(fullDF)))
  
  cols <- setdiff(cols, grep('^buzz',names(fullDF)))

  predFinal <- rep(0,dim(fullDF)[1])
  subSplit <- 'no'
  for (subSplit in c('no') ) { 
    trSubInd <- trInd
    teSubInd <- teInd
    valSubInd <- valInd

    parSize <- 5
    parSeed <- 1
    for (parSeed in 1:parSize) {
      # set different seed for each parallel model
      train_seed = 111 * parSeed
      pred <- rep(0,dim(fullDF)[1])
      if (parSize > 1) {
        #change train/validation if more parallel model needed
        ind0 <- c(trSubInd,valSubInd)
        set.seed(train_seed)
        ind <- createDataPartition(fullDF$TARGET[ind0],p=0.9,list=F)
        valSubInd <- ind0[-ind]
        trSubInd <- ind0[ind]
      }      
      source('code/xgb.R')
      predFinal <- predFinal + (pred / parSize)
    }
  }
  
  # score
  score <- c()
  if (train_metric == 'rmse') {
    score[1] <- evalRmse (predFinal[trInd], target[trInd])
    score[2] <- evalRmse (predFinal[teInd], target[teInd])
    score[3] <- evalRmse (predFinal[valInd], target[valInd])
  }

  OOFPred[teInd] <- predFinal[teInd]
  OOFPred[mainTeInd] <- OOFPred[mainTeInd] + (predFinal[mainTeInd] / foldSize)
  
  res <- rbind (res, t(c(scenario=scenario, fold=fold, score))) #, tree=mod_xgb$best_ntreelimit)))
  print (paste(scenario, fold , 'train - test - val score: ',  paste (score,collapse = ',') ,sep=' '))

}

names(res) <- c('scenario','fold','train','test','val')#,'tree')
res[,`:=`(train=as.numeric(train),test=as.numeric(test),val=as.numeric(val))]
res
res[,.(mean(train),mean(test),mean(val)),scenario]
res[,.(sd(train),sd(test),sd(val)),scenario]
