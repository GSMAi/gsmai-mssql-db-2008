
CREATE FUNCTION [dbo].[current_calendar_quarter]

()

RETURNS datetime

AS
BEGIN
	DECLARE @quarter int, @month varchar(2), @year varchar(4)

	SET @quarter = DATEPART(quarter, GETDATE())
	SET @year = CAST(DATEPART(year, GETDATE()) AS varchar(4))
	
	SELECT @month =
		CASE @quarter
			WHEN 1 THEN '01'
			WHEN 2 THEN '04'
			WHEN 3 THEN '07'
			WHEN 4 THEN '10'
		END

	RETURN CAST(@year + '-' + @month + '-01' AS datetime)
END
