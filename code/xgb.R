library(xgboost)

params <- list(booster = 'gbtree', eval_metric='rmse', objective='reg:linear'
               ,eta = 0.04, max_depth = 7, min_child_weight = 10, gamma=0.5, num_parallel_tree = 1
               ,subsample = 0.6, colsample_bytree = 0.6
               ,missing = NA, nthread = 7
)
nrounds <- 1000
early_stopping_rounds <- 20

table(sapply(fullDF[,.SD,.SDcols=cols],class))
fullDF$main.month = as.numeric(fullDF$main.month)
tr <- as.matrix(fullDF[trSubInd,.SD,.SDcols=cols])
te <- as.matrix(fullDF[teSubInd,.SD,.SDcols=cols])
val <- as.matrix(fullDF[valSubInd,.SD,.SDcols=cols])
mainTe <- as.matrix(fullDF[mainTeInd,.SD,.SDcols=cols])

trLabel <- target[trSubInd]
teLabel <- target[teSubInd]
valLabel <- target[valSubInd]

xgbTrain <- xgb.DMatrix(tr,label=trLabel)
xgbTest <- xgb.DMatrix(te,label=teLabel)
xgbVal <- xgb.DMatrix(val,label=valLabel)
xgbMainTe <- xgb.DMatrix(mainTe)

# train
if (exists('train_seed')) {
  set.seed(train_seed)
}

mod_xgb <- xgb.train(params, xgbTrain, nrounds=nrounds, watchlist = list(tr = xgbTrain, te = xgbTest, val=xgbVal)
                     , print_every_n = 20, early_stopping_rounds = early_stopping_rounds)

# predict
pred[trSubInd] <- predict(mod_xgb,xgbTrain)
pred[teSubInd] <- predict(mod_xgb,xgbTest)
pred[valSubInd] <- predict(mod_xgb,xgbVal)
pred[mainTeInd] <- predict(mod_xgb,xgbMainTe)

if (F) {
  impvar <- xgb.importance(colnames(tr),mod_xgb);impvar$N <- 1:dim(impvar)[1];impvar[,varN:=sapply(Feature,function(x,l) { which(x %in% l)[1]},names(fullDF)[cols])]
  xgb.plot.importance(impvar,top_n = 30)
}
