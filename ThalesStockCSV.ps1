# param([string]$DT)
$DT = '1705017599'
# Write-Host("The date passed is: " + $DT)
# period 1 978307200 corresponds to 2000-01-01
# period 2 1705017599 corresponds to 2021-01-11

########################################
######## Thales Stock Prices: ##########
########################################

# Yahoo Finances uses UNIX timestamp in the URL for dates
#########################################################

# Thales France Stock Prices (HO.PA) >>>>> EURO!!!<<<<<<<
Write-Host "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response1 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$THdata = $response1.Content | ConvertFrom-Csv

# Export the data to a CSV file
$THdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/thales_stock_prices.csv" -NoTypeInformation

########################################
######### Market Indicators: ###########
########################################

# Yahoo Finances uses UNIX timestamp in the URL for dates
#########################################################

# France Stock Market Indicator (^FCHI) >>>>> EURO!!!<<<<<<<

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/%5EFCHI?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response2 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/%5EFCHI?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$CACdata = $response2.Content | ConvertFrom-Csv

# Export the data to a CSV file
$CACdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/france_stock_market_index.csv" -NoTypeInformation

# S&P 500 Index (^SPX) >>>>> US Dollars!!!<<<<<<<

# Yahoo Finances uses UNIX timestamp in the URL for dates
#########################################################

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/%5ESPX?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response3 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/%5ESPX?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$SPdata = $response3.Content | ConvertFrom-Csv

# Export the data to a CSV file
$SPdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/standard_poor_500_index.csv" -NoTypeInformation

# Yahoo Finances uses UNIX timestamp in the URL for dates
#########################################################

# Euro Stoxx 50 eIndex >>>>> EURO!!!<<<<<<<

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/%5EGDAXI?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response4 = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/%5EGDAXI?period1=978307200&period2=$DT&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$daxdata = $response4.Content | ConvertFrom-Csv

# Export the data to a CSV file
$daxdata | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/euro_union-dax-data.csv" -NoTypeInformation