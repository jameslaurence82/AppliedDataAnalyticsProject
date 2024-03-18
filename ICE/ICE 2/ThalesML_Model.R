library(RODBC)
library(caret)
library(dplyr)
library(corrgram)
library(randomForest)
library(xgboost)

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

######################################################################################
# Split dataframe into Training, Validation, Testing before normalization
######################################################################################

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

######################################################################################
# Models Training
######################################################################################

