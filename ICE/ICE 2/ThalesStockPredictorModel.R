library(RODBC)
library(caret)
library(dplyr)
library(corrgram)


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
# # Remove the first Row (slice(-1)) of Data because of y Value and reset index
######################################################################################
Model_Data <- as.data.frame(Model_Data %>% slice(-1)) # NextDay_Close Null removed

# View the sliced Model_Data Dataframe
View(Model_Data)

# output to csv before ML steps
# write.csv(Model_Data, file = "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\ICE\\ICE 2\\Model_Norm.csv", row.names = FALSE)

# Work with a copy of the original Model_Date dataframe
Model_Norm <- as.data.frame(Model_Data) 

######################################################################################
# Correlation Matrix
######################################################################################
# Remove non-numeric columns if any (like Dates)
df_numeric <- Model_Norm[sapply(Model_Norm, is.numeric)]

# Calculate correlation
correlation_matrix <- cor(df_numeric)

# View correlation with THA_NextDay_Close
correlation_with_target <- correlation_matrix[, "THA_NextDay_Close"]

# Create correlation matrix
corrgram(df_numeric, order=TRUE, color.legend=TRUE)

######################################################################################
# Split dataframe into Training, Validation, Testing before normalization
######################################################################################

# Ensure reproducibility
set.seed(123)

# Proportion for training and validation sets
train_val_prop <- 0.8  

# Control object for stratified splitting
ctrl <- trainControl(strata = factor(data$THA_NextDay_Close))  

# Split index for training and validation sets
split_index <- createDataPartition(y = data$THA_NextDay_Close, times = 1, p = train_val_prop, stratifact = ctrl)

# Create training set
training_data <- data[split_index,]

# Create initial validation set
validation_data <- data[-split_index,]

# Proportion for testing set
test_prop <- 0.5

# Indices for testing set
test_idx <- sample(nrow(validation_data), round(test_prop * nrow(validation_data)))

# Create testing set
testing_data <- validation_data[test_idx, ]

# Finalize validation set
validation_data <- validation_data[-test_idx, ]

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

# Apply the normalize function to each numeric column that's not in the exclude_columns list
for (col_name in names(Model_Data)) {
  if (!(col_name %in% exclude_columns)) {
    Model_Norm[[col_name]] <- normalize(Model_Data[[col_name]])
  }
}

######################################################################################
#
######################################################################################


