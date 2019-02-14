# KaggleDaysParis
That was the top solution for quite a while on Kaggle Days Paris (https://kaggledays.com/paris/), finally end up as 3rd on private LB.

As you can see it's a simple solution with reduced number of features, no blending, no LB probing, no separated models for the different months. I think there are still lots of simple steps to improve.

Later i've realized that in the last 6 hours I couldn't improve the solution, although struggled a lot on feature selection ... 
Finally i've just put 5 parallel model in each fold to make it more robust.

# Solution

files in the code folder (it has to run in that order) :
  - fe.R : basic data transformations, feature engineering, creates "fe.base" file
  - fe_fold.R : fold related feature engineering, creates the 5 CV fold files: "fe.simple.1","fe.simple.2","fe.simple.3", etc.
  - train.R : train the models, 5 CV fold x 5 in parallel = 25 model and predicts the test set
  - subm2.R : create submission from the prediction

