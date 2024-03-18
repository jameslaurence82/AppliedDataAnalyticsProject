library(RODBC)
library(caret)
library(dplyr)
library(corrgram)
library(fields)
library(randomForest)
library(forecast)
library(xgboost)
library(glmnet)
library(lubridate)
library(scales)
library(rpart)
library(kernlab)
library(class)
library(party)
library(gbm)
library(stats)
library(gbm)
library(RSNNS)
library(rsample)

######################################################################################
# connect to sql server DB thalesstockpredictor to export vw_COMBINED_MODEL view
######################################################################################

# Sql server connection string
connStr <- "Driver=SQL Server;Server=MSI;Database=ThalesStockPredictor;trusted_connection=yes"

# establish connection
dbconnection <- odbcDriverConnect(connStr)
#
# query each view from sql server
# this is all the combined tables with y value column
query1 <- "SELECT * FROM vw_COMBINED_MODEL
          ORDER BY FK_DT_Date desc" # sorted with newest date

# assign the query to r dataframes for modeling
Model_Data <- sqlQuery(dbconnection, query1)
#
# close sql server connection
odbcClose(dbconnection)

# remove SQL variables
rm(connStr)
rm(query1)
rm(dbconnection)

######################################################################################
# Prep Model_Data DF for splitting Train/Test/Validate, normalization, correlation
######################################################################################

# output Model_Data to csv 
write.csv(Model_Data, file = "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\Model_Data.csv", row.names = FALSE)

# copy Model_Data to Model_Norm for ML steps
Model_Norm <- Model_Data

# change date column to be number date (UNIX Epoch)
Model_Norm$FK_DT_Date <- as.numeric(as.POSIXct(Model_Norm$FK_DT_Date))

# remove NA's which will also remove na' from lagged THA_NextDay_Close column
Model_Norm <- na.omit(Model_Norm)

# Reset row names
rownames(Model_Norm) <- NULL

######################################################################################
# Split dataframe into Training, Validation, Testing before normalization
######################################################################################

# # output Model_Norm to csv
# write.csv(Model_Data, file = "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\Model_Norm.csv", row.names = FALSE)

# Ensure reproducibility
set.seed(123)

# Proportion for training set
train_prop <- 0.8

# Split index for training set
train_index <- createDataPartition(y = Model_Norm$THA_NextDay_Close, times = 1, p = train_prop, list = FALSE)

# Create training set
training_data <- Model_Norm[train_index,]

# Create initial test set (which will be split into validation and test sets)
initial_test_data <- Model_Norm[-train_index,]

# Proportion for validation set (from the initial test set)
val_prop <- 0.5

# Split index for validation set
val_index <- createDataPartition(y = initial_test_data$THA_NextDay_Close, times = 1, p = val_prop, list = FALSE)

# Create validation set
validation_data <- initial_test_data[val_index,]

# Create testing set
testing_data <- initial_test_data[-val_index,]

# remove data split variables
rm(train_index)
rm(val_index)
rm(initial_test_data)
rm(train_prop)
rm(val_prop)

# remove data if issues after split
# rm(training_data)
# rm(testing_data)
# rm(validation_data)

######################################################################################
# NORMALIZE data
######################################################################################

# Build your own `normalize()` function
normalize <- function(x) {
  num <- x - min(x)
  denom <- max(x) - min(x)
  return (num/denom)
}

# Create a vector of column names to exclude
exclude_columns <- c("FK_DT_Date", "THA_NextDay_Close")

# Run normalization on all columns of the dataset (excluding the specified columns)
training_data[, setdiff(names(training_data), exclude_columns)] <- lapply(training_data[, setdiff(names(training_data), exclude_columns)], normalize)

# Run normalization on all columns of the dataset (excluding the specified columns)
validation_data[, setdiff(names(validation_data), exclude_columns)] <- lapply(validation_data[, setdiff(names(validation_data), exclude_columns)], normalize)

# Run normalization on all columns of the dataset (excluding the specified columns)
testing_data[, setdiff(names(testing_data), exclude_columns)] <- lapply(testing_data[, setdiff(names(testing_data), exclude_columns)], normalize)

# remove normalization variables
rm(normalize)
rm(exclude_columns)

modelLR <- train(THA_NextDay_Close ~ .,data = training_data, method = "lm", 
                 preProcess = c('scale', 'center')) # default: no pre-processing
modelLR

# RMSE     Rsquared  MAE      
# 1.10558  0.998864  0.7021597

modelRF <- train(THA_NextDay_Close ~ .,data = training_data, method = "rf", 
                 preProcess = 'knnImpute')
modelRF
######################################################################################
# Best Models Are: RF and GLM i think?
######################################################################################
# Assuming 'training_data' is your dataframe and 'THA_NextDay_Close' is your target variable
formula <- THA_NextDay_Close ~ .

# Define training control
train_control <- trainControl(method = "cv", number = 10)

# List of models to train
model1 <- c("rf", "glm")

# Empty list to store model results
model_list1 <- list()

# Train each model and store the results
for(model in model1) {
  set.seed(123)
  model_list1[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model1) {
  print(model_list1[[model]])
}

# Random Forest results
# mtry  RMSE      Rsquared   MAE      
# 2    1.095648  0.9988783  0.7113252
# 43    1.101919  0.9988591  0.7046351
# 85    1.107372  0.9988461  0.7107473

# Generalized Linear Model Results
# RMSE      Rsquared   MAE     
# 1.078353  0.9989071  0.687655

rm(model1)
rm(model_list1)

######################################################################################
# Model Hypertuning - GRID
######################################################################################

# Define training data (replace with your data)
train_data <- training_data

# Define hyperparameter grid for Random Forest (RF)
grid_rf <- expand.grid(
  mtry = c(3, 5, 10)  # This defines the column named 'mtry'
)

# Perform grid search with cross-validation for RF
rf_tuned <- train(
  formula = target ~ .,
  data = train_data,
  method = "rf",
  tuneGrid = grid_rf,
  trControl = train_control
)

# Access the best model with tuned hyperparameters
best_rf <- rf_tuned$bestModel


# Define hyperparameter grid for Generalized Linear Model (GLM)
grid_glm <- expand.grid(.alpha = seq(0, 1, by = 0.1))

# Perform grid search with cross-validation for GLM
glm_tuned <- train(
  formula = target ~ .,
  data = train_data,
  method = "glm",
  tuneGrid = grid_glm,
  trControl = ctrl
)

# Access the best models with tuned hyperparameters
best_rf <- rf_tuned$bestModel
best_glm <- glm_tuned$bestModel


# Evaluate the performance of the tuned models
# (e.g., using RMSE on a hold-out validation set)


######################################################################################
# Multiple model testing using ChatGPT
######################################################################################

# Assuming 'training_data' is your dataframe and 'THA_NextDay_Close' is your target variable
formula <- THA_NextDay_Close ~ .

# Define training control
train_control <- trainControl(method = "cv", number = 10)

# List of models to train
model1 <- c("rf", "knn")

# Empty list to store model results
model_list1 <- list()

# Train each model and store the results
for(model in model1) {
  set.seed(123)
  model_list1[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model1) {
  print(model_list1[[model]])
}

# Random Forest 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   mtry  RMSE      Rsquared   MAE      
# 2    1.095648  0.9988783  0.7113252
# 43    1.101919  0.9988591  0.7046351
# 85    1.107372  0.9988461  0.7107473
# 
# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was mtry = 2.
# k-Nearest Neighbors 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   k  RMSE      Rsquared   MAE      
# 5  1.167925  0.9987194  0.7345266
# 7  1.230654  0.9985824  0.7930008
# 9  1.335360  0.9983305  0.8560004
# 
# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was k = 5.
# Remove Model1 variables
rm(model1)
rm(model_list1)

# List of models to train
model2 <- c("lm", "gbm")

# Empty list to store model results
model_list2 <- list()

# Train each model and store the results
for(model in model2) {
  set.seed(123)
  model_list2[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model2) {
  print(model_list2[[model]])
}
# Linear Regression 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results:
#   
#   RMSE      Rsquared   MAE     
# 1.078353  0.9989071  0.687655
# 
# Tuning parameter 'intercept' was held constant at a value of TRUE
# Stochastic Gradient Boosting 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   interaction.depth  n.trees  RMSE      Rsquared   MAE      
# 1                   50      2.578986  0.9964674  1.7840819
# 1                  100      1.394545  0.9982109  0.9610244
# 1                  150      1.356022  0.9982722  0.9203136
# 2                   50      1.461888  0.9982523  1.0038552
# 2                  100      1.279939  0.9984641  0.8508868
# 2                  150      1.276908  0.9984697  0.8489189
# 3                   50      1.268868  0.9985629  0.8602324
# 3                  100      1.217235  0.9986088  0.8100303
# 3                  150      1.217755  0.9986088  0.8114758
# 
# Tuning parameter 'shrinkage' was held constant at a value of 0.1
# Tuning parameter 'n.minobsinnode' was held
# constant at a value of 10
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were n.trees = 100, interaction.depth = 3, shrinkage = 0.1 and n.minobsinnode
# = 10.
# Remove Model2 variables
rm(model2)
rm(model_list2)

# List of models to train
model3 <- c("rpart", "ctree")

# Empty list to store model results
model_list3 <- list()

# Train each model and store the results
for(model in model3) {
  set.seed(123)
  model_list3[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model3) {
  print(model_list3[[model]])
}
# CART 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   cp          RMSE       Rsquared   MAE      
# 0.03846636   8.584622  0.9292872   6.740351
# 0.09208200  12.522135  0.8494105   9.853617
# 0.81539661  25.238241  0.8087859  21.212671
# 
# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was cp = 0.03846636.
# Conditional Inference Tree 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   mincriterion  RMSE      Rsquared   MAE      
# 0.01          1.218860  0.9986083  0.8051115
# 0.50          1.187970  0.9986746  0.7853300
# 0.99          1.198236  0.9986504  0.7972819
# 
# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was mincriterion = 0.5.
# Remove Model3 variables
rm(model3)
rm(model_list3)

# List of models to train
model4 <- c("xgbLinear", "svmLinear")

# Empty list to store model results
model_list4 <- list()

# Train each model and store the results
for(model in model4) {
  set.seed(123)
  model_list4[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model4) {
  print(model_list4[[model]])
}
# eXtreme Gradient Boosting 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   lambda  alpha  nrounds  RMSE      Rsquared   MAE      
# 0e+00   0e+00   50      1.161906  0.9987312  0.7552048
# 0e+00   0e+00  100      1.169933  0.9987137  0.7641693
# 0e+00   0e+00  150      1.171893  0.9987096  0.7680140
# 0e+00   1e-04   50      1.160792  0.9987325  0.7527801
# 0e+00   1e-04  100      1.177322  0.9986970  0.7659773
# 0e+00   1e-04  150      1.179458  0.9986926  0.7688422
# 0e+00   1e-01   50      1.158659  0.9987387  0.7498890
# 0e+00   1e-01  100      1.167739  0.9987186  0.7600049
# 0e+00   1e-01  150      1.169651  0.9987145  0.7641075
# 1e-04   0e+00   50      1.157742  0.9987406  0.7505909
# 1e-04   0e+00  100      1.167555  0.9987198  0.7623593
# 1e-04   0e+00  150      1.170233  0.9987141  0.7665376
# 1e-04   1e-04   50      1.158536  0.9987368  0.7481663
# 1e-04   1e-04  100      1.170482  0.9987111  0.7603695
# 1e-04   1e-04  150      1.176707  0.9986975  0.7656976
# 1e-04   1e-01   50      1.149790  0.9987555  0.7473066
# 1e-04   1e-01  100      1.157265  0.9987388  0.7571377
# 1e-04   1e-01  150      1.159372  0.9987351  0.7612563
# 1e-01   0e+00   50      1.164284  0.9987266  0.7577767
# 1e-01   0e+00  100      1.173836  0.9987050  0.7686263
# 1e-01   0e+00  150      1.176792  0.9986992  0.7745770
# 1e-01   1e-04   50      1.156865  0.9987429  0.7550856
# 1e-01   1e-04  100      1.172051  0.9987099  0.7709110
# 1e-01   1e-04  150      1.175744  0.9987022  0.7754413
# 1e-01   1e-01   50      1.160998  0.9987319  0.7594133
# 1e-01   1e-01  100      1.171562  0.9987089  0.7701438
# 1e-01   1e-01  150      1.176124  0.9986993  0.7751660
# 
# Tuning parameter 'eta' was held constant at a value of 0.3
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were nrounds = 50, lambda = 1e-04, alpha = 0.1 and eta = 0.3.
# Support Vector Machines with Linear Kernel 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results:
#   
#   RMSE      Rsquared   MAE     
# 1.396765  0.9982076  1.050575
# 
# Tuning parameter 'C' was held constant at a value of 1

# Remove Model4 variables
rm(model4)
rm(model_list4)

# List of models to train
model5 <- c("glm", "mlp")

# Empty list to store model results
model_list5 <- list()

# Train each model and store the results
for(model in model5) {
  set.seed(123)
  model_list5[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model5) {
  print(model_list5[[model]])
}
# Generalized Linear Model 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results:
#   
#   RMSE      Rsquared   MAE     
# 1.078353  0.9989071  0.687655
# 
# Multi-Layer Perceptron 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   size  RMSE      Rsquared  MAE     
# 1     50.07566  NaN       42.63320
# 3     46.26605  NaN       38.25828
# 5     36.48873  NaN       29.64537
# 
# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was size = 5.
# Remove Model5 variables
rm(model5)
rm(model_list5)

# List of models to train
model6 <- c("nnet", "svmPoly")

# Empty list to store model results
model_list6 <- list()

# Train each model and store the results
for(model in model6) {
  set.seed(123)
  model_list6[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model6) {
  print(model_list6[[model]])
}
# Neural Network 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   size  decay  RMSE      Rsquared  MAE     
# 1     0e+00  64.99493  NaN       56.21565
# 1     1e-04  64.99493  NaN       56.21565
# 1     1e-01  64.99493  NaN       56.21565
# 3     0e+00  64.99493  NaN       56.21565
# 3     1e-04  64.99493  NaN       56.21565
# 3     1e-01  64.99493  NaN       56.21565
# 5     0e+00  64.99493  NaN       56.21565
# 5     1e-04  64.99493  NaN       56.21565
# 5     1e-01  64.99493  NaN       56.21565
# 
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were size = 1 and decay = 1e-04.
# Support Vector Machines with Polynomial Kernel 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   degree  scale  C     RMSE      Rsquared   MAE     
# 1       0.001  0.25  2.134540  0.9959838  1.688911
# 1       0.001  0.50  1.884834  0.9967699  1.469687
# 1       0.001  1.00  1.712027  0.9972804  1.314864
# 1       0.010  0.25  1.582063  0.9976547  1.197239
# 1       0.010  0.50  1.525546  0.9978205  1.149454
# 1       0.010  1.00  1.470188  0.9979778  1.106362
# 1       0.100  0.25  1.426531  0.9980947  1.071488
# 1       0.100  0.50  1.402719  0.9981658  1.048040
# 1       0.100  1.00  1.371392  0.9982740  1.023398
# 2       0.001  0.25  1.935389  0.9966516  1.561925
# 2       0.001  0.50  1.736620  0.9972700  1.368711
# 2       0.001  1.00  1.621345  0.9975794  1.259775
# 2       0.010  0.25  1.615029  0.9976238  1.264182
# 2       0.010  0.50  1.583580  0.9976874  1.209867
# 2       0.010  1.00  1.635016  0.9974999  1.199465
# 2       0.100  0.25  1.866083  0.9966111  1.331286
# 2       0.100  0.50  1.866078  0.9966111  1.331248
# 2       0.100  1.00  1.866078  0.9966111  1.331248
# 3       0.001  0.25  1.844417  0.9969378  1.485271
# 3       0.001  0.50  1.702809  0.9973378  1.348276
# 3       0.001  1.00  1.599410  0.9976319  1.250097
# 3       0.010  0.25  1.737982  0.9972746  1.347095
# 3       0.010  0.50  1.737669  0.9972449  1.329518
# 3       0.010  1.00  1.738495  0.9972349  1.328162
# 3       0.100  0.25  2.032283  0.9962337  1.638330
# 3       0.100  0.50  2.032283  0.9962337  1.638330
# 3       0.100  1.00  2.032283  0.9962337  1.638330
# 
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were degree = 1, scale = 0.1 and C = 1.
# Remove Model6 variables
rm(model6)
rm(model_list6)

# List of models to train
model7 <- c("svmRadial", "avNNet")

# Empty list to store model results
model_list7 <- list()

# Train each model and store the results
for(model in model7) {
set.seed(123)
model_list7[[model]] <- train(formula, data = training_data, trControl = train_control, method = model)
}

# Print the results
for(model in model7) {
print(model_list7[[model]])
}
# Support Vector Machines with Radial Basis Function Kernel 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   C     RMSE      Rsquared   MAE     
# 0.25  2.272204  0.9951156  1.598814
# 0.50  2.133610  0.9956916  1.516541
# 1.00  2.070545  0.9959529  1.487012
# 
# Tuning parameter 'sigma' was held constant at a value of 0.01280079
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were sigma = 0.01280079 and C = 1.
# Model Averaged Neural Network 
# 
# 4610 samples
# 85 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 4148, 4150, 4150, 4149, 4150, 4148, ... 
# Resampling results across tuning parameters:
#   
#   size  decay  RMSE      Rsquared  MAE     
# 1     0e+00  64.99493  NaN       56.21565
# 1     1e-04  64.99493  NaN       56.21565
# 1     1e-01  64.99493  NaN       56.21565
# 3     0e+00  64.99493  NaN       56.21565
# 3     1e-04  64.99493  NaN       56.21565
# 3     1e-01  64.99493  NaN       56.21565
# 5     0e+00  64.99493  NaN       56.21565
# 5     1e-04  64.99493  NaN       56.21565
# 5     1e-01  64.99493  NaN       56.21565
# 
# Tuning parameter 'bag' was held constant at a value of FALSE
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were size = 1, decay = 1e-04 and bag
# = FALSE.
# Remove Model7 variables
rm(model7)
rm(model_list7)



