# param([string]$DT)

# Write-Host("The date passed is: " + $DT)
# period 1 978307200 corresponds to January 1, 2001.
# period 2 1704424699 corresponds to January 5, 2024.

########################################
######## Thales Stock Prices: ##########
########################################

# Thales France Stock Prices
Write-Host "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response1 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$THdata = $response1.Content | ConvertFrom-Csv

# Export the data to a CSV file
$THdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/thales_stock_prices.csv" -NoTypeInformation

########################################
######### Market Indicators: ###########
########################################

# France Stock Market Indicator (CAC 40)

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/%5EFCHI?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response2 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/%5EFCHI?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$CACdata = $response2.Content | ConvertFrom-Csv

# Export the data to a CSV file
$CACdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/france_stock_market_index.csv" -NoTypeInformation

# S&P 500 Index (^SPX) >>>>> US Dollars!!!<<<<<<<

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/%5ESPX?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response3 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/%5ESPX?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$SPdata = $response3.Content | ConvertFrom-Csv

# Export the data to a CSV file
$SPdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/standard_poor_500_index.csv" -NoTypeInformation

# Dow Jones Industrial Average (^DJI)

Write-Host "https://stooq.com/q/d/l/?s=^dji&d1=978307200&d2=1704424699&i=d"

# Fetch the data
$response4 = Invoke-WebRequest -Uri "https://stooq.com/q/d/l/?s=^dji&d1=978307200&d2=1704424699&i=d"

# Convert the response content from a CSV string to objects
$DJIdata = $response4.Content | ConvertFrom-Csv

# Export the data to a CSV file
$DJIdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/dow_jones_industrial_avg.csv" -NoTypeInformation


########################################
######## Economic Indicators: ##########
########################################


# Economic Indicators: Websites of central banks, statistical agencies, and international organizations often provide historical economic data. 
# For example, the U.S. Federal Reserve’s FRED system has a vast array of economic data.

# Sector Performance: Financial news websites and platforms often provide data on sector performance. Additionally, specific industry 
# publications or databases may have relevant data.