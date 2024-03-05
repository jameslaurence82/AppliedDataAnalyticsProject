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
# Prep Model_Data DF for correlation, normalization, Train/Test/Validate split
######################################################################################

# View the sliced Model_Data Dataframe
View(Model_Data)

# output to csv before ML steps
# write.csv(Model_Data, file = "E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\Model_Norm.csv", row.names = FALSE)

# copy Model_Data and remove the first Row (slice(-1)), reset index as DF to Model_Norm
Model_Norm <- as.data.frame(Model_Data %>% slice(-1)) # NextDay_Close Null has entire row removed

######################################################################################
# Correlation Matrix
######################################################################################
# Remove non-numeric columns if any (like Dates)
df_numeric <- Model_Norm[sapply(Model_Norm, is.numeric)]

# copy df_numeric for null removal
df_naomit <- as.data.frame(df_numeric)

# # Calculate correlation with NA -----------> This Correlation Matrix is full of Nulls
# correlation_matrix <- cor(df_numeric)
# # View correlation with THA_NextDay_Close with NA
# correlation_with_target <- correlation_matrix[, "THA_NextDay_Close"]

# Calculate correlation - ignore NA
correlation_matrixNA <- cor(df_numeric, use = "complete.obs")  # ignores NA values
# View correlation with THA_NextDay_Close - ignore NA
correlation_with_targetNA <- correlation_matrixNA[, "THA_NextDay_Close"]

# Calculate correlation - Omit NA
correlation_matrixOmitNA <- cor(df_naomit)  # ignores NA values
# View correlation with THA_NextDay_Close - ignore NA
correlation_with_targetOmitNA <- correlation_matrixOmitNA[, "THA_NextDay_Close"]

# Start the png device with specified file path, name, and size
png("E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\corr_ignoreNA.png", width = 2000, height = 1024)

# Create the corrgram
corrgram(df_numeric, order=TRUE, lower.panel=panel.shade,
         upper.panel=panel.pie, text.panel=panel.txt, main="Correlation With Nulls Ignored")

# Add a color legend using image.plot
image.plot(legend.only=TRUE, col=colorRampPalette(c("blue", "white", "red"))(100), zlim=c(-1,1))

# Close the png device
dev.off()

# Start the png device with specified file path, name, and size
png("E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\corr_OmitNA.png", width = 2000, height = 1024)

# Create the corrgram
corrgram(df_naomit, order=TRUE, lower.panel=panel.shade,
         upper.panel=panel.pie, text.panel=panel.txt, main="Correlation With Nulls Omitted")

# Add a color legend using image.plot
image.plot(legend.only=TRUE, col=colorRampPalette(c("blue", "white", "red"))(100), zlim=c(-1,1))

# Close the png device
dev.off()

# Start the png device with specified file path, name, and size
png("E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\corr_barOmitNA.png", width = 2000, height = 1024)

# Create the bar plot with a title
barplot(correlation_with_targetOmitNA, main = "Correlation With Nulls Omitted to THA_NextDay_Close", horiz = TRUE, las = 1, cex.names=0.7)

# Close the png device
dev.off()


# Start the png device with specified file path, name, and size
png("E:\\5-Data Analytics Winter 2024\\DBAS3090 - Applied Data Analytics\\project\\ICE\\ICE 2\\corr_barignoreNA.png", width = 2000, height = 1024)

# Create the bar plot with a title
barplot(correlation_with_targetNA, main = "Correlation With Nulls Ignored to THA_NextDay_Close", horiz = TRUE, las = 1, cex.names=0.7)

# Close the png device
dev.off()

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


