
CREATE FUNCTION [dbo].[remove_outliers]
(
	@xy_data xy_data READONLY,				-- NOTE: the first row will be dropped as the comparison is made on net additions, so should pass n+1 data points for the time series n required
	@max_outlier_multiplier float = 2.5		-- Maximum net additions multiplier for outlier detection
)

-- Flags outliers and rebuilds an (x, y) data set based on adjusted net additions
RETURNS @xy_outliers TABLE (x float, y float)

AS

BEGIN
	DECLARE @row_midpoint float, @value float, @date datetime
	DECLARE @data TABLE (row int, date datetime, input float, input_2 float, value float, value_adjusted float, diff float, is_outlier bit, processed bit)

	INSERT INTO @data
	SELECT	ROW_NUMBER() OVER (ORDER BY xy.value), xy.date, xy.input, xy.input_2, xy.value, null, null, 0, 0
	FROM	(
				-- TODO: xy set manipulation without datetime dependency for traversing next/previous data point
				SELECT	dbo.excel_serial_to_datetime(xy2.x) date,
						xy.y input,
						xy2.y input_2,
						xy2.y - xy.y value

				FROM	@xy_data xy INNER JOIN
						@xy_data xy2 ON dbo.excel_serial_to_datetime(xy2.x) = DATEADD(quarter, 1, dbo.excel_serial_to_datetime(xy.x))
			) xy
	ORDER BY xy.value

	SET @row_midpoint = (SELECT AVG(row) FROM @data)

	-- Note: some semi-ridiculous use of inner queries/joins to satisfy SQL Server function requirement not to change state (disallows UPDATE)
	UPDATE @data SET diff = d.value - (SELECT AVG(d2.value) FROM @data d2 WHERE d2.row < d.row) FROM @data d WHERE d.row > @row_midpoint
	UPDATE @data SET diff = d.value - (SELECT AVG(d2.value) FROM @data d2 WHERE d2.row > d.row) FROM @data d WHERE d.row <= @row_midpoint

	UPDATE @data SET is_outlier = 1 FROM @data d WHERE d.row > @row_midpoint AND ABS(d.diff) > ABS(@max_outlier_multiplier * (SELECT d2.diff FROM @data d2 WHERE d2.row = d.row - 1))
	UPDATE @data SET is_outlier = 1 FROM @data d WHERE d.row <= @row_midpoint AND ABS(d.diff) > ABS(@max_outlier_multiplier * (SELECT d2.diff FROM @data d2 WHERE d2.row = d.row + 1))

	-- Adjust any outliers using surrounding values
	UPDATE @data SET value_adjusted = (d3.value - d2.value)/2 + d2.value FROM @data d INNER JOIN (SELECT * FROM @data) d2 ON d.date = DATEADD(quarter, 1, d2.date) INNER JOIN (SELECT * FROM @data) d3 ON d.date = DATEADD(quarter, -1, d3.date) WHERE d.is_outlier = 1

	IF (SELECT COUNT(*) FROM @data WHERE is_outlier = 1) > 0
	BEGIN
		-- Starting value is the y immediately prior to @period, net of any delta between the actual net additions and adjusted
		SET @value = (SELECT input FROM @data WHERE date = (SELECT MIN(date) FROM @data)) + (SELECT SUM(value) - SUM(value_adjusted) FROM @data WHERE is_outlier = 1)

		WHILE EXISTS (SELECT * FROM @data WHERE processed = 0)
		BEGIN
			SET @date = (SELECT TOP 1 date FROM @data WHERE processed = 0 ORDER BY date)

			-- Then each value here on is the current value plus the adjusted net additions
			SET @value = @value + (SELECT CASE WHEN value_adjusted IS null THEN value ELSE value_adjusted END FROM @data WHERE date = @date)

			INSERT INTO @xy_outliers
			SELECT dbo.datetime_to_excel_serial(@date), @value

			UPDATE @data SET processed = 1 WHERE date = @date
		END
	END

	RETURN
END
