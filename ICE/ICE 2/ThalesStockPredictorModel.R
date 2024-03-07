library(RODBC)
library(caret)
library(dplyr)
library(corrgram)
library(fields)

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

######################################################################################
# Prep Model_Data DF for splitting Train/Test/Validate, normalization, correlation
######################################################################################

# View the sliced Model_Data Dataframe
View(Model_Data)

# output to csv before ML steps
# write.csv(Model_Data, file = "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\Model_Norm.csv", row.names = FALSE)

# copy Model_Data and remove the first Row (slice(-1)), reset index as DF to Model_Norm
Model_Norm <- as.data.frame(Model_Data %>% slice(-1)) # NextDay_Close Null has entire row removed

######################################################################################
# Split dataframe into Training, Validation, Testing before normalization
######################################################################################
# Ensure reproducibility
set.seed(123)

# Load the caret package
library(caret)

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

######################################################################################
# NORMALIZE data
######################################################################################

# Build your own `normalize()` function
normalize <- function(x) {
  num <- x - min(x, na.rm = TRUE)  # Exclude NAs when computing min
  denom <- max(x, na.rm = TRUE) - min(x, na.rm = TRUE)  # Exclude NAs when computing max
  return(num / denom)
}

# Normalization columns to be excluded
exclude_columns <- c("FK_DT_Date", "THA_NextDay_Close")

# List of dataframes
dataframes <- list(training_data, validation_data, testing_data)

# Apply the normalize function to each numeric column that's not in the exclude_columns list
dataframes <- lapply(dataframes, function(df) {
  df[sapply(df, is.numeric)] <- lapply(df[sapply(df, is.numeric)], normalize)
  return(df)
})

# assigning function dataframes to named ML dataframes
training_data <- dataframes[[1]]
validation_data <- dataframes[[2]]
testing_data <- dataframes[[3]]

######################################################################################
# Correlation Matrix  <<<========= Purpose of this??????
######################################################################################

# Select only numeric columns
numeric_cols <- sapply(training_data, is.numeric)

# Calculate correlation of each numeric attribute with the target variable
correlations <- cor(training_data[, numeric_cols & !(names(training_data) %in% "THA_NextDay_Close")], training_data$THA_NextDay_Close, use = "pairwise.complete.obs")

# Print correlations
# print(correlations)

# Sort correlations in descending order
correlations_DESC <- sort(correlations, decreasing = TRUE)

# Sort correlations in descending order
correlations_ASC <- sort(correlations, decreasing = FALSE)

# Print correlations Desc
print(correlations_DESC)

# [1]  0.999458519  0.999267345  0.999246207  0.999057263  0.998514017  0.997265138  0.996634582
# [8]  0.995407461  0.995371085  0.995309969  0.993268583  0.991748248  0.988039718  0.977231300
# [15]  0.897755666  0.893179517  0.889102554  0.886785861  0.882705470  0.882394632  0.882374043
# [22]  0.882183811  0.881924737  0.881909066  0.881844758  0.881584467  0.881544161  0.881453035
# [29]  0.881396541  0.881396541  0.881345004  0.881300964  0.881217787  0.881117174  0.881044722
# [36]  0.880852706  0.880809467  0.880809467  0.880775395  0.880682216  0.880362395  0.879703636
# [43]  0.828622254  0.795085192  0.789404434  0.789404434  0.748371623  0.747565311  0.747565311
# [50]  0.747067078  0.746851318  0.746515752  0.746095803  0.745816513  0.745244628  0.745231144
# [57]  0.742713989  0.742334198  0.742208489  0.731596263  0.275789523  0.257949787  0.165056122
# [64]  0.139542041  0.139147150  0.118758390  0.115460117  0.107668139  0.103403168  0.098534043
# [71]  0.096829854  0.086585685  0.067186730  0.060233957  0.057972173  0.044069911  0.038927757
# [78]  0.030724009  0.028085835 -0.001325216 -0.002437406 -0.113685222 -0.188901029 -0.306218543
####################### WHAT DO I DO AFTER KNOWING CORR VALUES????#####################

# Print correlations ASC
print(correlations_ASC)
# [1] -0.306218543 -0.188901029 -0.113685222 -0.002437406 -0.001325216  0.028085835  0.030724009
# [8]  0.038927757  0.044069911  0.057972173  0.060233957  0.067186730  0.086585685  0.096829854
# [15]  0.098534043  0.103403168  0.107668139  0.115460117  0.118758390  0.139147150  0.139542041
# [22]  0.165056122  0.257949787  0.275789523  0.731596263  0.742208489  0.742334198  0.742713989
# [29]  0.745231144  0.745244628  0.745816513  0.746095803  0.746515752  0.746851318  0.747067078
# [36]  0.747565311  0.747565311  0.748371623  0.789404434  0.789404434  0.795085192  0.828622254
# [43]  0.879703636  0.880362395  0.880682216  0.880775395  0.880809467  0.880809467  0.880852706
# [50]  0.881044722  0.881117174  0.881217787  0.881300964  0.881345004  0.881396541  0.881396541
# [57]  0.881453035  0.881544161  0.881584467  0.881844758  0.881909066  0.881924737  0.882183811
# [64]  0.882374043  0.882394632  0.882705470  0.886785861  0.889102554  0.893179517  0.897755666
# [71]  0.977231300  0.988039718  0.991748248  0.993268583  0.995309969  0.995371085  0.995407461
# [78]  0.996634582  0.997265138  0.998514017  0.999057263  0.999246207  0.999267345  0.999458519
####################### WHAT DO I DO AFTER KNOWING CORR VALUES????#####################

######################################################################################
# build Linear Regression MOdels - Random Forest <<<========= Purpose of this??????
######################################################################################
# Load the randomForest package
library(randomForest)

# omit NA in training data
training_dataOMITna <- na.omit(training_data)

# Fit the model <-------- Omit NA values
rf_modelOMITna <- randomForest(THA_NextDay_Close ~ ., data = training_dataOMITna, importance = TRUE)

# Get feature importance
importance <- importance(rf_modelOMITna)

# Get names of features with importance < 1
features_to_remove <- names(importance[importance < 1])

# Remove these features from the dataframe
df_reduced <- training_dataOMITna[, !(names(training_dataOMITna) %in% features_to_remove)]

######################################################################################
# remove vars before model build  <<<========= Purpose of this??????
######################################################################################
rm(correlation_matrixNA)
rm(correlation_matrixOmitNA)
rm(correlation_matrixOmitOmitNA)
rm(dataframes)
rm(train_index)
rm(val_index)
rm(df_numeric)
rm(df_naomit)
rm(imputed_data)
rm(training_dataIMPUTE)
rm(imputed_data)
rm(initial_test_data)
rm(correlation_with_targetNA)
rm(correlation_with_targetOmitNA)
rm(correlations)
rm(correlations_ASC)
rm(correlations_ASCC)
rm(correlations_DESC)
rm(sorted_features)
rm(dbconnection)
rm(train_prop)
rm(train_val_prop)
rm(val_prop)
rm(connStr)
rm(exclude_columns)
rm(numeric_cols)
rm(query1)


######################################################################################
# Model Selection  <<<========= NO IDEA
######################################################################################

# Using all rows of your training data
modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = c('scale', 'center'))
modelLR
# Output: RMSE for your data

# Predict on your validation set
validation_predictions <- predict(modelLR, newdata = validation_data)

# Calculate RMSE for the validation set
validation_RMSE <- postResample(pred = validation_predictions, obs = validation_data$THA_NextDay_Close)

# Predict on your test set
test_predictions <- predict(modelLR, newdata = test_data)

# Calculate RMSE for the test set
test_RMSE <- postResample(pred = test_predictions, obs = test_data$THA_NextDay_Close)


modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = 'pca')
modelLR
# Output: RMSE for your data

modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = 'BoxCox')
modelLR
# Output: RMSE for your data

modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = 'YeoJohnson')
modelLR
# Output: RMSE for your data

modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = 'bagImpute')
modelLR
# Output: RMSE for your data

modelLR <- train(THA_NextDay_Close ~ ., data = training_dataOMITna, method = "lm", 
                 preProcess = 'knnImpute')
modelLR
# Output: RMSE for your data

