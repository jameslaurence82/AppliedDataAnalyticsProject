library(RODBC)
library(caret)
library(randomForest)
library(doParallel)
library(foreach)

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

# copy Model_Data to Model_Norm for ML steps
Model_Norm <- Model_Data

# change date column to be number date (UNIX Epoch)
Model_Norm$FK_DT_Date <- as.numeric(as.POSIXct(Model_Norm$FK_DT_Date))

# remove NA's which will also remove na' from lagged y predictor THA_NextDay_Close column
Model_Norm <- na.omit(Model_Norm)

# Reset row names
rownames(Model_Norm) <- NULL

rm(Model_Data)
######################################################################################
# Split dataframe into Training, Validation, Testing before normalization
######################################################################################

# Ensure reproducibility
set.seed(123)

# Proportion for training set
train_prop <- 0.9

# Split index for training set
train_index <- createDataPartition(y = Model_Norm$THA_NextDay_Close, times = 1, p = train_prop, list = FALSE)

# Create training set
training_data <- Model_Norm[train_index,]

# Create initial test set (which will be split into validation and test sets)
testing_data <- Model_Norm[-train_index,]

# remove data split variables
rm(train_index)
rm(train_prop)

######################################################################################
# Increase Core Use for caret library
######################################################################################

# Register the parallel backend
registerDoParallel(cores=9)

######################################################################################
# Feature Importance - Random Forest
######################################################################################

modelRF_importance <- randomForest(THA_NextDay_Close ~ ., data = training_data[1:5186,], trControl = fitControl,)

# Get feature importance
importance <- importance(modelRF_importance)

# Sort the importance in descending order
importance_sorted <- sort(importance, decreasing = TRUE, index.return = TRUE)

# Get the names of the sorted features
feature_names <- rownames(importance)[importance_sorted$ix]

# Combine the names and importance into a data frame
importance_df <- data.frame(Feature = feature_names, Importance = importance_sorted$x)

# Print the data frame
options(scipen = 999)  # This will disable scientific notation
print(importance_df)

######################################################################################
# Feature Importance - Random Forest Model Training
######################################################################################

# Filter the features with importance above 60
important_features <- importance_df$Feature[importance_df$Importance > 60]

# Create a new training dataset with only the important features
train_x <- training_data[important_features]

# Add the target variable to the new training dataset
train_x$THA_NextDay_Close <- training_data$THA_NextDay_Close

fitControl <- trainControl(method = "repeatedcv", 
                           number = 10,     # number of folds
                           repeats = 10)

modelRF.cv <- train(THA_NextDay_Close ~ ., data = train_x, method = "rf", trControl = fitControl)

modelRF.cv
# mtry  RMSE      Rsquared   MAE      
#  2    1.052131  0.9989709  0.6721646
# 31    1.097282  0.9988783  0.6959071
# 60    1.106284  0.9988601  0.7038500

######################################################################################
# compare unseen Test data Random Forest
######################################################################################

# Create a new testing dataset with only the important features
test_x <- testing_data[important_features]

# Define test_y
test_y <- testing_data$THA_NextDay_Close

# Use model to make predictions on test data
pred_y = predict(modelRF.cv, test_x)

# Test Performance
# Performance metrics on the test data
caret::RMSE(test_y, pred_y) # RMSE - Root Mean Squared Error


# TEST RSME
# [1] 1.012785
##############

pred= cbind.data.frame(test_y,pred_y)
pred
# Last Rows in console
#        test_y    pred_y
# 4754  30.58000  29.73852
# 4782  28.71000  29.27385
# 4783  29.13000  29.28360
# 4811  26.09000  26.62205
# 4824  26.16000  26.16478
# 4834  24.72000  25.20768
# 4838  25.71000  25.50832
# 4842  24.89000  24.97314
# 4852  24.65000  24.54762
# 4854  24.70000  24.60044
# 4865  24.00000  24.55215
# 4866  24.30000  25.02568
# 4881  26.85000  26.37367
# 4892  27.68000  27.06381
# 4905  26.87000  27.42953
# 4920  27.05000  26.47123
# 4921  25.72000  25.56448

######################################################################################
# Stop Additional Core Use
######################################################################################

# Stop parallel processing
stopImplicitCluster()

######################################################################################
# Save the best model --> RandomForest Using Feature Importance
######################################################################################

saveRDS(modelRF.cv, "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\Project\\ICE\\ICE 2\\rfModel.rds")

######################################################################################
# loading Saved Model for Predictions --> RandomForest Using Feature Importance
######################################################################################

savedRF_Model <- readRDS("E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\Project\\ICE\\ICE 2\\rfModel.rds")

#use model to make predictions on test data
pred_y = predict(savedRF_Model, test_x)

#Test Performance from Saved Model File
# performance metrics on the test data
caret::RMSE(test_y, pred_y) #rmse - Root Mean Squared Error

# RSME
# [1] 1.012785

# Predictions from Saved Model File
pred= cbind.data.frame(test_y,pred_y)
pred
# Last Rows in console
# 4866  24.30000  25.02568
# 4881  26.85000  26.37367
# 4892  27.68000  27.06381
# 4905  26.87000  27.42953
# 4920  27.05000  26.47123
# 4921  25.72000  25.56448