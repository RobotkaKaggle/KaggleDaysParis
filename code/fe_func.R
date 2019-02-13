library(data.table)

factDistCreate <- function (df) {
  factorSize <- sapply(df, function(x) { if (is.factor(x)) { return (length(levels(x)));} else { return (-1);} } )
  
  facts <- which(factorSize >= 0)
  factDist <- data.table()
  # if there's not TARGET
  if (!('TARGET' %in% names(df))) {
    TARGET <- 0
  }
  for (fact in facts) {
    factName <- names(df)[fact];
    factDist <- rbind (factDist, df[,.(col=factName,lev=factorSize[fact],n=.N,s=sum(TARGET),m=mean(TARGET),sd=sd(TARGET)),by=eval(as.name(factName))])
  }
  names(factDist)[1] <- 'val'
  #factDist[,p := s/n]
  factDist[,d := n/dim(df)[1]]
  #factDist <- factDist[!is.na(val),]
  return (factDist)
}

factDistApply <- function (pop, factDist, minCatNr = 5, minCount = 50) {
  factNames <- names(pop)[which (names(pop) %in% factDist[lev >= minCatNr,.N,col][,col])]
  for (factName in factNames) {
    pop <- merge(pop, factDist[col == factName & n >= minCount,.(val,m)], by.x = factName , by.y = 'val', all.x = T, sort = F)
    names(pop)[dim(pop)[2]] <- paste(factName,'avg',sep='.')
  }
  return (pop)
}

factToDummy <- function (pop, factDist, minCatProb = 0.01, maxCatNr = 5) {
  facts <- which (names(pop) %in% factDist[,.N,col][,col])
  for (fact in facts) {
    factName <- names(pop)[fact];
    vals <- factDist[col == factName & d >= minCatProb,.(d,val),][order(d, decreasing = T),as.character(val)]
    if (length(vals) > maxCatNr) vals <- vals[1:maxCatNr]
    if (length(vals) > 0) {
      for (val in vals) {
        pop[,newCol := as.integer(0)]
        pop[eval(as.name(factName)) == val,newCol := 1]
        names(pop)[dim(pop)[2]] <- paste(factName,val,sep='.')
      }
    }
  }
  return (pop)
}

evalRmse <- function (score, label) {
  # rmse
  return (sqrt(mean((score -label)^2)))
}

