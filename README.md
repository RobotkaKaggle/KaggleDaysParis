# KaggleDaysParis
That was the top solution for quite a while on Kaggle Days Paris (https://kaggledays.com/paris/)

As you can see it's a simple solution with reduced number of features, no blending, no LB probing, although the feature selection was quite a problem and took long ... 

Interesting that in the last 6 hours i couldn't improve the solution, finally just put 5 parallel model for each fold to make it more robust.

# Solution

in the code folder there are:
  - fe.R : basic data transformations, feature engineering
  - fe_fold.R : fold base feature engineering
  - train.R : train the models, 5 CV fold x 5 in parallel = 25 model 
  - subm2.R : create submission from the model
