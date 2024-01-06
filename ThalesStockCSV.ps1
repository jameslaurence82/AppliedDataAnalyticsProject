# param([string]$DT)

# Write-Host("The date passed is: " + $DT)
# period 1 978307200 corresponds to January 1, 2001.
# period 2 1704424699 corresponds to January 5, 2024.

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Fetch the data
$response = Invoke-WebRequest -Uri "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

# Convert the response content from a CSV string to objects
$data = $response.Content | ConvertFrom-Csv

# Export the data to a CSV file
$data | Export-Csv -Path "E:/5-Data Analytics Winter 2024/DBAS3090 - Applied Data Analytics/Project/thales_stock_prices.csv" -NoTypeInformation

# Market Indicators: Many financial news websites and platforms provide historical data for major market indicators like the S&P 500 or 
# Dow Jones Industrial Average. Examples include Yahoo Finance, Google Finance, and Bloomberg.

# Economic Indicators: Websites of central banks, statistical agencies, and international organizations often provide historical economic data. 
# For example, the U.S. Federal Reserve’s FRED system has a vast array of economic data.

# Sector Performance: Financial news websites and platforms often provide data on sector performance. Additionally, specific industry 
# publications or databases may have relevant data.