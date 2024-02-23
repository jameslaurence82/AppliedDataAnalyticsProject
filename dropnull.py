import pandas as pd

# load the 4 dirty csvs from yahoo finance into dataframes
thales = pd.read_csv('dirtyThales_Stock.csv')
france = pd.read_csv('dirtyFRA_Index.csv')
sp500 = pd.read_csv('dirtySP500_INDEX.csv')
euro = pd.read_csv('dirtyEURO_Index.csv')

# remove nulls from dirty dataframes
clean_thales = thales.dropna()
clean_france = france.dropna()
clean_sp500 = sp500.dropna()
clean_euro = euro.dropna()

# export clean dataframes to become clean csv's without panda's index column
clean_thales.to_csv("clean_thales.csv", index=False)
clean_france.to_csv("clean_france.csv", index=False)
clean_sp500.to_csv("clean_sp500.csv", index=False)
clean_euro.to_csv("clean_euro.csv", index=False)