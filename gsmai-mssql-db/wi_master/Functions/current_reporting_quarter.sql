
CREATE FUNCTION [dbo].[current_reporting_quarter]

()

RETURNS datetime

AS
BEGIN
	DECLARE @m int, @y int, @month varchar(2), @year varchar(4)

	SET @m = DATEPART(month, GETDATE())
	SET @y = DATEPART(year, GETDATE())

	SELECT @month =
		CASE @m
			WHEN 4 THEN '01'
			WHEN 5 THEN '01'
			WHEN 6 THEN '01'

			WHEN 7 THEN '04'
			WHEN 8 THEN '04'
			WHEN 9 THEN '04'

			WHEN 10 THEN '07'
			WHEN 11 THEN '07'
			WHEN 12 THEN '07'

			WHEN 1 THEN '10'
			WHEN 2 THEN '10'
			WHEN 3 THEN '10'
		END

	SELECT @year =
		CASE @month
			WHEN '10' THEN CAST(@y-1 AS varchar)
			ELSE CAST(@y AS varchar)
		END

	RETURN CAST(@year + '-' + @month + '-01' AS datetime)
END
