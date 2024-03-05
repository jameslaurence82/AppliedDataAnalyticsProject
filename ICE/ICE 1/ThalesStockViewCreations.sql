-----------------------------------------------
-- DROP VIEWS
-----------------------------------------------
--DROP VIEW [dbo].[vw_COMBINED_TABLES];
--DROP VIEW [dbo].[vw_COMBINED_RSI];
--DROP VIEW [dbo].[vw_COMBINED_OBV];
--DROP VIEW [dbo].[vw_COMBINED_BB];
--DROP VIEW [dbo].[vw_COMBINED_MA];
--DROP VIEW [dbo].[vw_COMBINED_MACD];
--DROP VIEW [dbo].[vw_COMBINED_MODEL];
--DROP VIEW [dbo].[vw_EUR_BB];
--DROP VIEW [dbo].[vw_EUR_MA];
--DROP VIEW [dbo].[vw_EUR_MACD];
--DROP VIEW [dbo].[vw_EUR_OBV];
--DROP VIEW [dbo].[vw_EUR_RSI];
--DROP VIEW [dbo].[vw_FRA_BB];
--DROP VIEW [dbo].[vw_FRA_MA];
--DROP VIEW [dbo].[vw_FRA_MACD];
--DROP VIEW [dbo].[vw_FRA_OBV];
--DROP VIEW [dbo].[vw_FRA_RSI];
--DROP VIEW [dbo].[vw_SPI_BB];
--DROP VIEW [dbo].[vw_SPI_MA];
--DROP VIEW [dbo].[vw_SPI_MACD];
--DROP VIEW [dbo].[vw_SPI_OBV];
--DROP VIEW [dbo].[vw_SPI_RSI];
--DROP VIEW [dbo].[vw_THA_BB];
--DROP VIEW [dbo].[vw_THA_MA];
--DROP VIEW [dbo].[vw_THA_MACD];
--DROP VIEW [dbo].[vw_THA_OBV];
--DROP VIEW [dbo].[vw_THA_RSI];
-----------------------------------------------
-- Creation of the Feature Engineering Views For Model--
-----------------------------------------------

-------------------------------------------
-- create a vw_COMBINED_TABLES 
-- (all tables plus THA_NextDay_Close column for model
-------------------------------------------
CREATE VIEW vw_COMBINED_TABLES AS
SELECT 
    T.FK_DT_Date,
    T.THALES_Open AS THA_Open, 
    T.THALES_High AS THA_High,
    T.THALES_Low AS THA_Low,
    T.THALES_Close AS THA_Close,
    T.THALES_Adj_Close AS THA_Adj_Close,
    T.THALES_Volume AS THA_Volume,
    LEAD(T.THALES_Close, 1) OVER (ORDER BY T.FK_DT_Date) AS THA_NextDay_Close,
    S.SPI_Open,
    S.SPI_High,
    S.SPI_Low,
    S.SPI_Close,
    S.SPI_Adj_Close,
    S.SPI_Volume,
    F.FRA_Open,
    F.FRA_High,
    F.FRA_Low,
    F.FRA_Close,
    F.FRA_Adj_Close,
    F.FRA_Volume,
    E.EUR_Open,
    E.EUR_High,
    E.EUR_Low,
    E.EUR_Close,
    E.EUR_Adj_Close,
    E.EUR_Volume
FROM 
    THALES_STOCK T
LEFT JOIN 
    S_P_INDEX S ON T.FK_DT_Date = S.FK_DT_Date
LEFT JOIN 
    FRANCE_INDEX F ON T.FK_DT_Date = F.FK_DT_Date
LEFT JOIN 
    EURO_INDEX E ON T.FK_DT_Date = E.FK_DT_Date;
GO
-------------------------------------------
-- Create vw_THA_RSI view
-------------------------------------------
CREATE VIEW vw_THA_RSI AS
WITH RS_CTE AS (
  SELECT
    FK_DT_Date,
    THALES_Close,
    LAG(THALES_Close) OVER (ORDER BY FK_DT_Date) AS PrevClose
  FROM THALES_STOCK
), RS_CTE2 AS (
  SELECT
    FK_DT_Date,
    CASE WHEN THALES_Close > PrevClose THEN THALES_Close - PrevClose ELSE 0 END AS UpMove,
    CASE WHEN THALES_Close < PrevClose THEN PrevClose - THALES_Close ELSE 0 END AS DownMove
  FROM RS_CTE
), RS_CTE3 AS (
  SELECT 
    FK_DT_Date,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS UpMove_7,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS DownMove_7,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS UpMove_30,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS DownMove_30,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS UpMove_90,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS DownMove_90,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS UpMove_180,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS DownMove_180
  FROM RS_CTE2
)
SELECT 
  FK_DT_Date,
  CASE 
    WHEN UpMove_7 = 0 OR DownMove_7 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_7 / DownMove_7))))
  END AS RSI_RSI_7,
  CASE 
    WHEN UpMove_30 = 0 OR DownMove_30 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_30 / DownMove_30))))
  END AS RSI_RSI_30,
  CASE 
    WHEN UpMove_90 = 0 OR DownMove_90 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_90 / DownMove_90))))
  END AS RSI_RSI_90,
  CASE 
    WHEN UpMove_180 = 0 OR DownMove_180 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_180 / DownMove_180))))
  END AS RSI_RSI_180
FROM RS_CTE3
GO
-------------------------------------------
-- Create vw_FRA_RSI view
-------------------------------------------
CREATE VIEW vw_FRA_RSI AS
WITH RS_CTE AS (
  SELECT
    FK_DT_Date,
    FRA_Close,
    LAG(FRA_Close) OVER (ORDER BY FK_DT_Date) AS PrevClose
  FROM FRANCE_INDEX
), RS_CTE2 AS (
  SELECT
    FK_DT_Date,
    CASE WHEN FRA_Close > PrevClose THEN FRA_Close - PrevClose ELSE 0 END AS UpMove,
    CASE WHEN FRA_Close < PrevClose THEN PrevClose - FRA_Close ELSE 0 END AS DownMove
  FROM RS_CTE
), RS_CTE3 AS (
  SELECT 
    FK_DT_Date,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS UpMove_7,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS DownMove_7,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS UpMove_30,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS DownMove_30,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS UpMove_90,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS DownMove_90,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS UpMove_180,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS DownMove_180
  FROM RS_CTE2
)
SELECT 
  FK_DT_Date,
  CASE 
    WHEN UpMove_7 = 0 OR DownMove_7 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_7 / DownMove_7))))
  END AS RSI_RSI_7,
  CASE 
    WHEN UpMove_30 = 0 OR DownMove_30 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_30 / DownMove_30))))
  END AS RSI_RSI_30,
  CASE 
    WHEN UpMove_90 = 0 OR DownMove_90 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_90 / DownMove_90))))
  END AS RSI_RSI_90,
  CASE 
    WHEN UpMove_180 = 0 OR DownMove_180 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_180 / DownMove_180))))
  END AS RSI_RSI_180
FROM RS_CTE3
GO
------------------------------------
-- Create vw_SPI_RSI view
------------------------------------
CREATE VIEW vw_SPI_RSI AS
WITH RS_CTE AS (
  SELECT
    FK_DT_Date,
    SPI_Close,
    LAG(SPI_Close) OVER (ORDER BY FK_DT_Date) AS PrevClose
  FROM S_P_INDEX
), RS_CTE2 AS (
  SELECT
    FK_DT_Date,
    CASE WHEN SPI_Close > PrevClose THEN SPI_Close - PrevClose ELSE 0 END AS UpMove,
    CASE WHEN SPI_Close < PrevClose THEN PrevClose - SPI_Close ELSE 0 END AS DownMove
  FROM RS_CTE
), RS_CTE3 AS (
  SELECT 
    FK_DT_Date,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS UpMove_7,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS DownMove_7,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS UpMove_30,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS DownMove_30,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS UpMove_90,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS DownMove_90,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS UpMove_180,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS DownMove_180
  FROM RS_CTE2
)
SELECT 
  FK_DT_Date,
  CASE 
    WHEN UpMove_7 = 0 OR DownMove_7 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_7 / DownMove_7))))
  END AS RSI_RSI_7,
  CASE 
    WHEN UpMove_30 = 0 OR DownMove_30 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_30 / DownMove_30))))
  END AS RSI_RSI_30,
  CASE 
    WHEN UpMove_90 = 0 OR DownMove_90 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_90 / DownMove_90))))
  END AS RSI_RSI_90,
  CASE 
    WHEN UpMove_180 = 0 OR DownMove_180 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_180 / DownMove_180))))
  END AS RSI_RSI_180
FROM RS_CTE3
GO
------------------------------------
-- Create vw_EUR_RSI view
------------------------------------
CREATE VIEW vw_EUR_RSI AS
WITH RS_CTE AS (
  SELECT
    FK_DT_Date,
    EUR_Close,
    LAG(EUR_Close) OVER (ORDER BY FK_DT_Date) AS PrevClose
  FROM EURO_INDEX
), RS_CTE2 AS (
  SELECT
    FK_DT_Date,
    CASE WHEN EUR_Close > PrevClose THEN EUR_Close - PrevClose ELSE 0 END AS UpMove,
    CASE WHEN EUR_Close < PrevClose THEN PrevClose - EUR_Close ELSE 0 END AS DownMove
  FROM RS_CTE
), RS_CTE3 AS (
  SELECT 
    FK_DT_Date,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS UpMove_7,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS DownMove_7,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS UpMove_30,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS DownMove_30,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS UpMove_90,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS DownMove_90,
    AVG(UpMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS UpMove_180,
    AVG(DownMove) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) AS DownMove_180
  FROM RS_CTE2
)
SELECT 
  FK_DT_Date,
  CASE 
    WHEN UpMove_7 = 0 OR DownMove_7 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_7 / DownMove_7))))
  END AS RSI_RSI_7,
  CASE 
    WHEN UpMove_30 = 0 OR DownMove_30 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_30 / DownMove_30))))
  END AS RSI_RSI_30,
  CASE 
    WHEN UpMove_90 = 0 OR DownMove_90 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_90 / DownMove_90))))
  END AS RSI_RSI_90,
  CASE 
    WHEN UpMove_180 = 0 OR DownMove_180 = 0 THEN NULL
    ELSE (100 - (100 / (1 + (UpMove_180 / DownMove_180))))
  END AS RSI_RSI_180
FROM RS_CTE3
GO
------------------------------------
-- Create vw_THA_MA view
------------------------------------
CREATE VIEW vw_THA_MA AS
SELECT 
    FK_DT_Date,
    AVG(THALES_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as MA_7day,
    AVG(THALES_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as MA_30day,
    AVG(THALES_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) as MA_90day,
    AVG(THALES_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) as MA_180day
FROM 
    THALES_STOCK
GO
------------------------------------
-- Create vw_SPI_MA view
------------------------------------
CREATE VIEW vw_SPI_MA AS
SELECT 
    FK_DT_Date,
    AVG(SPI_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as MA_7day,
    AVG(SPI_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as MA_30day,
    AVG(SPI_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) as MA_90day,
    AVG(SPI_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) as MA_180day
FROM 
    S_P_INDEX
GO
------------------------------------
-- Create vw_FRA_MA view
------------------------------------
CREATE VIEW vw_FRA_MA AS
SELECT 
    FK_DT_Date,
    AVG(FRA_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as MA_7day,
    AVG(FRA_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as MA_30day,
    AVG(FRA_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) as MA_90day,
    AVG(FRA_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) as MA_180day
FROM 
    FRANCE_INDEX
GO
------------------------------------
-- Create vw_EUR_MA view
------------------------------------
CREATE VIEW vw_EUR_MA AS
SELECT 
    FK_DT_Date,
    AVG(EUR_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as MA_7day,
    AVG(EUR_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as MA_30day,
    AVG(EUR_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) as MA_90day,
    AVG(EUR_Close) OVER (ORDER BY FK_DT_Date ROWS BETWEEN 179 PRECEDING AND CURRENT ROW) as MA_180day
FROM 
    EURO_INDEX;
GO
-------------------------------------------
-- Create vw_THA_OBV views for each table
-------------------------------------------
CREATE VIEW vw_THA_OBV AS
WITH OBV_Calc AS (
    SELECT 
        FK_DT_Date,
        CASE 
            WHEN THALES_Close > LAG(THALES_Close) OVER (ORDER BY FK_DT_Date) THEN THALES_Volume
            WHEN THALES_Close < LAG(THALES_Close) OVER (ORDER BY FK_DT_Date) THEN -THALES_Volume
            WHEN THALES_Close = LAG(THALES_Close) OVER (ORDER BY FK_DT_Date) THEN
                CASE 
                    WHEN THALES_Close > LAG(THALES_Close, 2) OVER (ORDER BY FK_DT_Date) THEN THALES_Volume
                    WHEN THALES_Close < LAG(THALES_Close, 2) OVER (ORDER BY FK_DT_Date) THEN -THALES_Volume
                    ELSE 0 END
            ELSE 0 END AS VolumeChange
    FROM dbo.THALES_STOCK
)
SELECT 
    FK_DT_Date,
    SUM(VolumeChange) OVER (ORDER BY FK_DT_Date) AS OBV_OBV
FROM OBV_Calc
GO
-------------------------------------------
-- Create vw_SPI_OBV views for each table
-------------------------------------------
CREATE VIEW vw_SPI_OBV AS
WITH OBV_Calc AS (
    SELECT 
        FK_DT_Date,
        CASE 
            WHEN SPI_Close > LAG(SPI_Close) OVER (ORDER BY FK_DT_Date) THEN SPI_Volume
            WHEN SPI_Close < LAG(SPI_Close) OVER (ORDER BY FK_DT_Date) THEN -SPI_Volume
            WHEN SPI_Close = LAG(SPI_Close) OVER (ORDER BY FK_DT_Date) THEN
                CASE 
                    WHEN SPI_Close > LAG(SPI_Close, 2) OVER (ORDER BY FK_DT_Date) THEN SPI_Volume
                    WHEN SPI_Close < LAG(SPI_Close, 2) OVER (ORDER BY FK_DT_Date) THEN -SPI_Volume
                    ELSE 0 END
            ELSE 0 END AS VolumeChange
    FROM dbo.S_P_INDEX
)
SELECT 
    FK_DT_Date,
    SUM(VolumeChange) OVER (ORDER BY FK_DT_Date) AS OBV_OBV
FROM OBV_Calc
GO
-------------------------------------------
-- Create vw_FRA_OBV views for each table
-------------------------------------------
CREATE VIEW vw_FRA_OBV AS
WITH OBV_Calc AS (
    SELECT 
        FK_DT_Date,
        CASE 
            WHEN FRA_Close > LAG(FRA_Close) OVER (ORDER BY FK_DT_Date) THEN FRA_Volume
            WHEN FRA_Close < LAG(FRA_Close) OVER (ORDER BY FK_DT_Date) THEN -FRA_Volume
            WHEN FRA_Close = LAG(FRA_Close) OVER (ORDER BY FK_DT_Date) THEN
                CASE 
                    WHEN FRA_Close > LAG(FRA_Close, 2) OVER (ORDER BY FK_DT_Date) THEN FRA_Volume
                    WHEN FRA_Close < LAG(FRA_Close, 2) OVER (ORDER BY FK_DT_Date) THEN -FRA_Volume
                    ELSE 0 END
            ELSE 0 END AS VolumeChange
    FROM dbo.FRANCE_INDEX
)
SELECT 
    FK_DT_Date,
    SUM(VolumeChange) OVER (ORDER BY FK_DT_Date) AS OBV_OBV
FROM OBV_Calc
GO
-------------------------------------------
-- Create vw_EUR_OBV views for each table
-------------------------------------------
CREATE VIEW vw_EUR_OBV AS
WITH OBV_Calc AS (
    SELECT 
        FK_DT_Date,
        CASE 
            WHEN EUR_Close > LAG(EUR_Close) OVER (ORDER BY FK_DT_Date) THEN EUR_Volume
            WHEN EUR_Close < LAG(EUR_Close) OVER (ORDER BY FK_DT_Date) THEN -EUR_Volume
            WHEN EUR_Close = LAG(EUR_Close) OVER (ORDER BY FK_DT_Date) THEN
                CASE 
                    WHEN EUR_Close > LAG(EUR_Close, 2) OVER (ORDER BY FK_DT_Date) THEN EUR_Volume
                    WHEN EUR_Close < LAG(EUR_Close, 2) OVER (ORDER BY FK_DT_Date) THEN -EUR_Volume
                    ELSE 0 END
            ELSE 0 END AS VolumeChange
    FROM dbo.EURO_INDEX
)
SELECT 
    FK_DT_Date,
    SUM(VolumeChange) OVER (ORDER BY FK_DT_Date) AS OBV_OBV
FROM OBV_Calc
GO
-------------------------------------------
-- Create individual vw_THA_BB view
-------------------------------------------
CREATE VIEW vw_THA_BB AS
SELECT
  FK_DT_Date,
  THALES_Close,
  AVG(THALES_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS SMA,
  AVG(THALES_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) + 2 * STDEV(THALES_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS UpperBand,
  AVG(THALES_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) - 2 * STDEV(THALES_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS LowerBand
FROM
  dbo.THALES_STOCK
GO
-------------------------------------------
-- Create individual vw_SPI_BB view
-------------------------------------------
CREATE VIEW vw_SPI_BB AS
SELECT
  FK_DT_Date,
  SPI_Close,
  AVG(SPI_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS SMA,
  AVG(SPI_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) + 2 * STDEV(SPI_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS UpperBand,
  AVG(SPI_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) - 2 * STDEV(SPI_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS LowerBand
FROM
  dbo.S_P_INDEX
GO
-------------------------------------------
-- Create individual vw_FRA_BB view
-------------------------------------------
CREATE VIEW vw_FRA_BB AS
SELECT
  FK_DT_Date,
  FRA_Close,
  AVG(FRA_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS SMA,
  AVG(FRA_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) + 2 * STDEV(FRA_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS UpperBand,
  AVG(FRA_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) - 2 * STDEV(FRA_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS LowerBand
FROM
  dbo.FRANCE_INDEX
GO
-------------------------------------------
-- Create individual vw_EUR_BB view
-------------------------------------------
CREATE VIEW vw_EUR_BB AS
SELECT
  FK_DT_Date,
  EUR_Close,
  AVG(EUR_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS SMA,
  AVG(EUR_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) + 2 * STDEV(EUR_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS UpperBand,
  AVG(EUR_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) - 2 * STDEV(EUR_Close) OVER (
    ORDER BY FK_DT_Date
    ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
  ) AS LowerBand
FROM
  dbo.EURO_INDEX
GO
-------------------------------------------
-- Create individual vw_THA_MACD views
-------------------------------------------
CREATE VIEW vw_THA_MACD AS
WITH THA_EMA AS (
SELECT FK_DT_Date,
	AVG(THALES_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 12 FOLLOWING) AS THA_EMA12,
		AVG(THALES_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 26 FOLLOWING) AS THA_EMA26
FROM THALES_STOCK
)
SELECT * ,
(THA_EMA12 - THA_EMA26) as THA_MACD
FROM THA_EMA
GO
-------------------------------------------
-- Create individual vw_SPI_MACD views
-------------------------------------------
CREATE VIEW vw_SPI_MACD AS
WITH SPI_EMA AS (
SELECT FK_DT_Date,
	AVG(SPI_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 12 FOLLOWING) AS SPI_EMA12,
		AVG(SPI_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 26 FOLLOWING) AS SPI_EMA26
FROM S_P_INDEX
)
SELECT * ,
(SPI_EMA12 - SPI_EMA26) as SPI_MACD
FROM SPI_EMA
GO
-------------------------------------------
-- Create individual vw_FRA_MACD views
-------------------------------------------
CREATE VIEW vw_FRA_MACD AS
WITH FRA_EMA AS (
SELECT FK_DT_Date,
	AVG(FRA_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 12 FOLLOWING) AS FRA_EMA12,
		AVG(FRA_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 26 FOLLOWING) AS FRA_EMA26
FROM FRANCE_INDEX
)
SELECT * ,
(FRA_EMA12 - FRA_EMA26) as FRA_MACD
FROM FRA_EMA
GO
-------------------------------------------
-- Create individual vw_EUR_MACD views
-------------------------------------------
CREATE VIEW vw_EUR_MACD AS
WITH EUR_EMA AS (
SELECT FK_DT_Date,
	AVG(EUR_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 12 FOLLOWING) AS EUR_EMA12,
		AVG(EUR_Close) OVER (ORDER BY FK_DT_Date DESC ROWS BETWEEN 1 FOLLOWING AND 26 FOLLOWING) AS EUR_EMA26
FROM EURO_INDEX
)
SELECT * ,
(EUR_EMA12 - EUR_EMA26) as EUR_MACD
FROM EUR_EMA
GO
-------------------------------------------
-- Create combined view for all vw_COMBINED_MACD views
-------------------------------------------
CREATE VIEW vw_COMBINED_MACD AS
SELECT
  -- THA MACD
	T.FK_DT_Date,
	T.THA_EMA12,
	T.THA_EMA26,
	T.THA_MACD,
  -- EUR MACD
	E.EUR_EMA12,
	E.EUR_EMA26,
	E.EUR_MACD,
  -- SPI MACD
	S.SPI_EMA12,
	S.SPI_EMA26,
	S.SPI_MACD,
  -- FRA MACD
	F.FRA_EMA12,
	F.FRA_EMA26,
	F.FRA_MACD
FROM vw_THA_MACD AS T
LEFT JOIN 
vw_SPI_MACD AS S ON T.FK_DT_Date = S.FK_DT_Date
LEFT JOIN 
vw_FRA_MACD AS F ON T.FK_DT_Date = F.FK_DT_Date
LEFT JOIN 
vw_EUR_MACD AS E ON T.FK_DT_Date = E.FK_DT_Date;
GO
-------------------------------------------
-- Create vw_COMBINED_RSI view
-------------------------------------------
CREATE VIEW vw_COMBINED_RSI AS
SELECT 
    E.FK_DT_Date,
    E.RSI_RSI_7 AS EUR_RSI_7,
    E.RSI_RSI_30 AS EUR_RSI_30,
    E.RSI_RSI_90 AS EUR_RSI_90,
    E.RSI_RSI_180 AS EUR_RSI_180,
    S.RSI_RSI_7 AS SPI_RSI_7,
    S.RSI_RSI_30 AS SPI_RSI_30,
    S.RSI_RSI_90 AS SPI_RSI_90,
    S.RSI_RSI_180 AS SPI_RSI_180,
    F.RSI_RSI_7 AS FRA_RSI_7,
    F.RSI_RSI_30 AS FRA_RSI_30,
    F.RSI_RSI_90 AS FRA_RSI_90,
    F.RSI_RSI_180 AS FRA_RSI_180,
    T.RSI_RSI_7 AS THA_RSI_7,
    T.RSI_RSI_30 AS THA_RSI_30,
    T.RSI_RSI_90 AS THA_RSI_90,
    T.RSI_RSI_180 AS THA_RSI_180
FROM 
    vw_EUR_RSI E
LEFT JOIN
    vw_SPI_RSI S ON E.FK_DT_Date = S.FK_DT_Date
LEFT JOIN
    vw_FRA_RSI F ON E.FK_DT_Date = F.FK_DT_Date
LEFT JOIN
    vw_THA_RSI T ON E.FK_DT_Date = T.FK_DT_Date
GO
------------------------------------
-- Create vw_COMBINED_MA view
------------------------------------
CREATE VIEW vw_COMBINED_MA AS
SELECT 
    T.FK_DT_Date,
	T.MA_7day AS THA_MA_7day,
    T.MA_30day AS THA_MA_30day,
    T.MA_90day AS THA_MA_90day,
    T.MA_180day AS THA_MA_180day,
    E.MA_7day AS EUR_MA_7day,
    E.MA_30day AS EUR_MA_30day,
    E.MA_90day AS EUR_MA_90day,
    E.MA_180day AS EUR_MA_180day,
    S.MA_7day AS SPI_MA_7day,
    S.MA_30day AS SPI_MA_30day,
    S.MA_90day AS SPI_MA_90day,
    S.MA_180day AS SPI_MA_180day,
    F.MA_7day AS FRA_MA_7day,
    F.MA_30day AS FRA_MA_30day,
    F.MA_90day AS FRA_MA_90day,
    F.MA_180day AS FRA_MA_180day
FROM 
    vw_THA_MA T
LEFT JOIN 
    vw_SPI_MA S ON T.FK_DT_Date = S.FK_DT_Date
LEFT JOIN 
    vw_FRA_MA F ON T.FK_DT_Date = F.FK_DT_Date
LEFT JOIN 
    vw_EUR_MA E ON E.FK_DT_Date = T.FK_DT_Date
GO
-------------------------------------------
-- Create combined vw_COMBINED_BB view
-------------------------------------------
CREATE VIEW vw_COMBINED_BB AS
SELECT
  -- THA BB
  T.FK_DT_Date,
  T.SMA AS THA_SMA,
  T.UpperBand AS THA_UpperBand,
  T.LowerBand AS THA_LowerBand,
  -- EUR BB
  E.SMA AS EUR_SMA,
  E.UpperBand AS EUR_UpperBand,
  E.LowerBand AS EUR_LowerBand,
  -- SPI BB
  S.SMA AS SPI_SMA,
  S.UpperBand AS SPI_UpperBand,
  S.LowerBand AS SPI_LowerBand,
  -- FRA BB
  F.SMA AS FRA_SMA,
  F.UpperBand AS FRA_UpperBand,
  F.LowerBand AS FRA_LowerBand
FROM vw_THA_BB T
LEFT JOIN 
vw_SPI_BB S ON T.FK_DT_Date = S.FK_DT_Date
LEFT JOIN 
vw_FRA_BB F ON T.FK_DT_Date = F.FK_DT_Date
LEFT JOIN 
vw_EUR_BB E ON T.FK_DT_Date = E.FK_DT_Date;
GO
-------------------------------------------
-- Create vw_COMBINED_OBV view that combines all OBV views
-------------------------------------------
CREATE VIEW vw_COMBINED_OBV AS
SELECT 
    E.FK_DT_Date,
	T.OBV_OBV AS THA_OBV,
    E.OBV_OBV AS EUR_OBV,
    S.OBV_OBV AS SPI_OBV,
    F.OBV_OBV AS FRA_OBV
FROM 
    vw_EUR_OBV T
LEFT JOIN 
    vw_SPI_OBV S ON T.FK_DT_Date = S.FK_DT_Date
LEFT JOIN 
    vw_FRA_OBV F ON T.FK_DT_Date = F.FK_DT_Date
LEFT JOIN 
    vw_EUR_OBV E ON T.FK_DT_Date = E.FK_DT_Date
GO
-------------------------------------------
-- create a vw_COMBINED_MODEL
--------------------------------------------------------------------------------------
CREATE VIEW vw_COMBINED_MODEL AS (
   SELECT CT.*, 
	-- COMBINED_TABLES
	-- COMBINED_MACD
	MACD.THA_EMA12,
	MACD.THA_EMA26,
	MACD.THA_MACD,
	MACD.EUR_EMA12,
	MACD.EUR_EMA26,
	MACD.EUR_MACD,
	MACD.SPI_EMA12,
	MACD.SPI_EMA26,
	MACD.SPI_MACD,
	MACD.FRA_EMA12,
	MACD.FRA_EMA26,
	MACD.FRA_MACD,
	-- COMBINED_RSI
	RSI.EUR_RSI_7,
    RSI.EUR_RSI_30,
    RSI.EUR_RSI_90,
    RSI.EUR_RSI_180,
    RSI.SPI_RSI_7,
    RSI.SPI_RSI_30,
    RSI.SPI_RSI_90,
    RSI.SPI_RSI_180,
    RSI.FRA_RSI_7,
    RSI.FRA_RSI_30,
    RSI.FRA_RSI_90,
    RSI.FRA_RSI_180,
    RSI.THA_RSI_7,
    RSI.THA_RSI_30,
    RSI.THA_RSI_90,
    RSI.THA_RSI_180,
	-- COMBINED_MA
	MA.THA_MA_7day,
    MA.THA_MA_30day,
    MA.THA_MA_90day,
    MA.THA_MA_180day,
    MA.EUR_MA_7day,
    MA.EUR_MA_30day,
    MA.EUR_MA_90day,
    MA.EUR_MA_180day,
    MA.SPI_MA_7day,
    MA.SPI_MA_30day,
    MA.SPI_MA_90day,
    MA.SPI_MA_180day,
    MA.FRA_MA_7day,
    MA.FRA_MA_30day,
    MA.FRA_MA_90day,
    MA.FRA_MA_180day,
	-- COMBINE_BB
	BB.THA_SMA,
	BB.THA_UpperBand,
	BB.THA_LowerBand,
	BB.EUR_SMA,
	BB.EUR_UpperBand,
	BB.EUR_LowerBand,
	BB.SPI_SMA,
	BB.SPI_UpperBand,
	BB.SPI_LowerBand,
	BB.FRA_SMA,
	BB.FRA_UpperBand,
	BB.FRA_LowerBand,
	-- COMBINE_OBV
	OBV.THA_OBV,
    OBV.EUR_OBV,
    OBV.SPI_OBV,
    OBV.FRA_OBV
    FROM vw_COMBINED_TABLES CT
    LEFT JOIN 
	vw_COMBINED_OBV OBV ON CT.FK_DT_Date = OBV.FK_DT_Date
    LEFT JOIN 
	vw_COMBINED_MA MA ON CT.FK_DT_Date = MA.FK_DT_Date
    LEFT JOIN 
	vw_COMBINED_BB BB ON CT.FK_DT_Date = BB.FK_DT_Date
    LEFT JOIN 
	vw_COMBINED_RSI RSI ON CT.FK_DT_Date = RSI.FK_DT_Date
    LEFT JOIN 
	vw_COMBINED_MACD MACD ON CT.FK_DT_Date = MACD.FK_DT_Date
);