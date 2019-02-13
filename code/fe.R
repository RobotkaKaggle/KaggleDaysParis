rm(list=ls())
setwd('c:/kaggle/lvCleaned')
source('code/fe_func.R')

library(data.table)
library(caret)
library(stringi)
library(lubridate)

df <- fread(input='data/train.csv',stringsAsFactors = T)
tf <- fread(input='data/test.csv',stringsAsFactors = T)

# create pop from train and test
target <- log(df$target+1)
id <- df$sku_hash
df[,`:=`(target=NULL,ID=id,sku_hash=NULL)]
df[,TARGET:=target]

id <- tf$sku_hash
tf[,`:=`(TARGET=NA,ID=id,sku_hash=NULL)]
pop <- rbind(df,tf)
names(pop)[2:(dim(pop)[2]-1)] <- paste('main',names(pop)[2:(dim(pop)[2]-1)],sep='.')
rm(df,tf)

# create folds on ID level
set.seed(111)
popFold <- pop[!is.na(TARGET),.(m=mean(TARGET)),ID]
popFold[,folds := createFolds(m, k = 5, list=F)]
#popFold[,.(mean(m),.N),folds]

pop <- merge(pop,popFold[,.(ID,folds)],by='ID',all.x = T)
pop[is.na(folds),folds := 0]
#pop[,.(mean(TARGET),.N,length(unique(ID))),folds]
rm(popFold)

# FEATURES
if (T) {
  pop$ID <- as.character(pop$ID)
  popFactDist <- factDistCreate(pop[folds != 0,])
  pop <- factToDummy(pop,popFactDist,minCatProb = 0.01, maxCatNr = 50)
}

# SALES DATA FEATURES
if (T) {
  h1 <- fread(input='data/sales.csv',stringsAsFactors = T)
  cols <- 1:dim(h1)[2]
  cols <- setdiff(cols,grep('^currency',names(h1)))
  cols <- setdiff(cols,grep('day_before',names(h1)))
  h1 <- h1[,cols,with=F]
  
  h1[,ID:=as.character(sku_hash)]
  h1[,sku_hash:=NULL]
  h1[,Month_transaction:=as.factor(Month_transaction)]
  h1[,zone_number:=as.factor(zone_number)]
  h1[,country_number:=as.factor(country_number)]
  
  # sales_quantity stats for each factor variable: Date,day_transaction_date,Month_transaction,type,zone_number,country_number,name
  cols <- names(h1)[which(sapply(h1,class) == 'factor')]
  col <- cols[1]
  for (col in cols) {
    h2 <- h1[,.(sq=sum(sales_quantity)),.(ID,c=eval(as.name(col)))]
    h3 <- dcast(h2,'ID ~ c',value.var = 'sq', sep='.', fill = 0)
    names(h3)[2:dim(h3)[2]] <- paste('sq',col,names(h3)[2:dim(h3)[2]],sep='.')
    pop <- merge(pop,h3,by='ID',all.x = T, sort = F)
    if (col == 'Date') {
      h4 <- h2[,.(min(sq),max(sq),mean(sq),sd(sq),sum(sq)),ID]
      names(h4)[2:6] <- paste('sq',c('min','max','mean','sd','sum'),col,sep='.')
      pop <- merge(pop,h4,by='ID',all.x = T, sort = F)
    } else {
      h4 <- h2[,.(min(sq),max(sq),mean(sq),sd(sq)),ID]
      names(h4)[2:5] <- paste('sq',c('min','max','mean','sd'),col,sep='.')
      pop <- merge(pop,h4,by='ID',all.x = T, sort = F)
    }
  }

  h2 <- h1[,.(TotalBuzzPost=max(TotalBuzzPost),TotalBuzz=max(TotalBuzz),NetSentiment=max(NetSentiment),PositiveSentiment=max(PositiveSentiment),NegativeSentiment=max(NegativeSentiment),Impressions=max(Impressions)),.(ID,Date)]
  cols <- c('TotalBuzzPost','TotalBuzz','NetSentiment','PositiveSentiment','NegativeSentiment','Impressions')
  col <- cols[1]
  # Buzz sum data for each date: Day_1, Day_2, etc.
  for (col in cols) {
    h3 <- dcast(h2,'ID ~ Date',value.var = col, sep='.', fill = 0)
    names(h3)[2:dim(h3)[2]] <- paste('buzz',col,names(h3)[2:dim(h3)[2]],sep='.')
    pop <- merge(pop,h3,by='ID',all.x = T, sort = F)
  }
}

fwrite(pop, 'data/fe.base.csv')
