scenario <- 'base'
subm <- data.table(ID = paste(fullDF$ID[mainTeInd],fullDF$main.month[mainTeInd],sep='_'),target=exp(OOFPred[mainTeInd])-1)
subm[,.N,target][,.N]
fwrite(subm, paste('./subm/subm',scenario,res[,mean(test)],'txt',sep='.'))
