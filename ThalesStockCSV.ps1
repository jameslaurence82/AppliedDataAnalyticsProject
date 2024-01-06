# param([string]$DT)

Write-Host("The date passed is: " + $DT)
# period 1 978307200 corresponds to January 1, 2001.
# period 2 1704424699 corresponds to January 5, 2024.

Write-Host "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"

$data= Invoke-RestMethod -Uri "https://query1.finance.yahoo.com/v7/finance/download/HO.PA?period1=978307200&period2=1704424699&interval=1d&events=history&includeAdjustedClose=true"
# Thales Stock Prices Data
$data | export-csv -path "E:\4-Data Analytics Fall 2023\DBAS3019 - Business Data Modelling\ICE\ICE 2\PSAPIDownload\thales_stock_prices.csv" -NoTypeInformation
# Start-Sleep -Seconds 3.5