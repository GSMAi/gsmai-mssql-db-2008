
CREATE PROCEDURE [dbo].[api_curve_fit]

(
	@show tinyint = 1,
	@organisation_id int,
	@last_historic_quarter datetime,
	@min_r2 float						= 0.9,		-- Minimum value of R-square for fit to pass
	@max_variance float					= 0.03,		-- Maximum variance of any value for fit to pass
	@max_yoy_multiplier float			= 1.5,		-- Maximum year-on-year additions for fit to pass
	@max_outlier_multiplier float		= 2.5		-- Maximum net additions multiplier for outlier detection
)

AS

DECLARE @xy_data xy_data, @xy_data_2 xy_data, @xy_outliers xy_data, @xy_forecasts xy_data
DECLARE @periods ordered_iterator, @period char(8), @y_bar float, @r2_bar float, @years int, @weight_1 float, @weight_2 float, @weight_3 float, @weight_4 float, @year_1 int, @year_2 int, @year_3 int, @year_4 int, @date datetime, @value float, @fk char(32)

CREATE TABLE #data (organisation_id int, metric_id int, attribute_id int, date_type char(1), date datetime, date_excel int, value float)
CREATE TABLE #net_additions (date datetime, input float, input_2 float, value float, value_weighted float, processed bit)
CREATE TABLE #fitted_data (fk char(32), period char(8), include_seasonality bit, exclude_outliers bit, type char(8), x float, y float, x_datetime datetime)
CREATE TABLE #fit (fk char(32), period char(8), include_seasonality bit, exclude_outliers bit, type char(8), a float, b float, c float, d float, r2 float, y_bar float, max_variance float, yoy_multiplier float, has_criteria bit)


-- Fetch existing connections data up to and including @last_historic_quarter
INSERT INTO #data
SELECT	organisation_id, metric_id, attribute_id, date_type, date, dbo.datetime_to_excel_serial(date), CAST(val_i AS float)
FROM	ds_organisation_data
WHERE	organisation_id = @organisation_id AND metric_id = 3 AND attribute_id = 0 AND date_type = 'Q' AND date >= DATEADD(quarter, -16, @last_historic_quarter) AND date <= @last_historic_quarter		-- Require 17 quarters of data for a full 16 quarters of net additions


-- Require at least 9 rows of data in order to get a half-decent statistical fit
IF (SELECT COUNT(*) FROM #data) >= 9
BEGIN
	-- Prepare an xy forecast series for trending
	INSERT INTO @xy_data
	SELECT d.* FROM (SELECT TOP 16 date_excel, value FROM #data ORDER BY date DESC) d ORDER BY d.date_excel

	-- A second xy set contains an additional row for x as the outlier detection works on net additions; row will be discarded, see dbo.remove_outliers
	INSERT INTO @xy_data_2
	SELECT d.* FROM (SELECT TOP 17 date_excel, value FROM #data ORDER BY date DESC) d ORDER BY d.date_excel

	INSERT INTO @xy_forecasts
	SELECT dbo.datetime_to_excel_serial(DATEADD(quarter, 1, @last_historic_quarter)), null UNION ALL
	SELECT dbo.datetime_to_excel_serial(DATEADD(quarter, 2, @last_historic_quarter)), null UNION ALL
	SELECT dbo.datetime_to_excel_serial(DATEADD(quarter, 3, @last_historic_quarter)), null UNION ALL
	SELECT dbo.datetime_to_excel_serial(DATEADD(quarter, 4, @last_historic_quarter)), null

	-- Iterate 2-, 3- and 4-year periods (if available) and return the base fitting data
	SET @years = (SELECT CEILING(CAST(COUNT(x)/4 AS float)) FROM @xy_data)

	INSERT INTO @periods
	SELECT 1, '4-year', 0 UNION ALL
	SELECT 2, '3-year', 0 UNION ALL
	SELECT 3, '2-year', 0

	WHILE EXISTS (SELECT * FROM @periods WHERE processed = 0)
	BEGIN
		SET @period	= (SELECT TOP 1 term FROM @periods WHERE processed = 0 ORDER BY [order])

		-- Create fits for baseline data
		SET @y_bar	= (SELECT AVG(y) FROM @xy_data)

		INSERT INTO #fit
		SELECT	null, @period, 0, 0, *, @y_bar, null, null, 0
		FROM	curve_best_fit_coefficients_only(@xy_data, 0)

		INSERT INTO #fitted_data
		SELECT	null, @period, 0, 0, *, dbo.excel_serial_to_datetime(x)
		FROM	curve_best_fit(@xy_data, @xy_forecasts, 0)

		-- Remove outliers and re-run the fit, if appropriate
		INSERT INTO @xy_outliers
		SELECT * FROM dbo.remove_outliers(@xy_data_2, @max_outlier_multiplier)

		IF (SELECT COUNT(*) FROM @xy_outliers) > 0
		BEGIN
			SET @y_bar	= (SELECT AVG(y) FROM @xy_outliers)

			INSERT INTO #fit
			SELECT	null, @period, 0, 1, *, @y_bar, null, null, 0
			FROM	curve_best_fit_coefficients_only(@xy_outliers, 0)

			INSERT INTO #fitted_data
			SELECT	null, @period, 0, 1, *, dbo.excel_serial_to_datetime(x)
			FROM	curve_best_fit(@xy_outliers, @xy_forecasts, 0)
		END

		DELETE FROM @xy_data WHERE x IN (SELECT TOP 4 x FROM @xy_data ORDER BY x)
		DELETE FROM @xy_data_2 WHERE x IN (SELECT TOP 4 x FROM @xy_data_2 ORDER BY x)
		DELETE FROM @xy_outliers

		UPDATE @periods SET processed = 1 WHERE term = @period
	END


	-- Then map the fitted data against the original data set to calculate AVG(variance) over all Q1/2/3/4s in the set to assess seasonality and feed this back in as a separate variation of the fitted model
	CREATE TABLE #seasonality_variance (period char(8), exclude_outliers bit, quarter int, value float)

	INSERT INTO #seasonality_variance
	SELECT		fd.period, fd.exclude_outliers, DATEPART(quarter, d.date), AVG(d.value - fd.y)
	FROM		#fitted_data fd INNER JOIN #data d ON fd.x_datetime = d.date
	WHERE		fd.x_datetime <= @last_historic_quarter
	GROUP BY	fd.period, fd.exclude_outliers, DATEPART(quarter, d.date)

	INSERT INTO #fitted_data
	SELECT		null, fd.period, 1, fd.exclude_outliers, fd.type, fd.x, fd.y + sv.value, dbo.excel_serial_to_datetime(x)
	FROM		#fitted_data fd INNER JOIN #seasonality_variance sv ON (fd.period = sv.period AND fd.exclude_outliers = sv.exclude_outliers AND sv.quarter = DATEPART(quarter, fd.x_datetime))

	DROP TABLE #seasonality_variance


	-- Add a row key to reduce required joins
	UPDATE #fit SET fk = RTRIM(period) + '|' + RTRIM(type) + '|' + CAST(include_seasonality AS char(1)) + '|' + CAST(exclude_outliers AS char(1))
	UPDATE #fitted_data SET fk = RTRIM(period) + '|' + RTRIM(type) + '|' + CAST(include_seasonality AS char(1)) + '|' + CAST(exclude_outliers AS char(1))


	-- Insert combinations of the model that don't yet exist in the statistics table but have been computed as adjusted-fit models
	INSERT INTO #fit (period, include_seasonality, exclude_outliers, type, has_criteria)
	SELECT		DISTINCT fd.period, fd.include_seasonality, fd.exclude_outliers, fd.type, 0
	FROM		#fitted_data fd LEFT JOIN #fit f ON f.fk = fd.fk
	WHERE		f.fk IS null

	UPDATE f SET f.y_bar = f2.y_bar FROM #fit f INNER JOIN #fit f2 ON f.period = f2.period WHERE f.y_bar IS null
	UPDATE #fit SET fk = RTRIM(period) + '|' + RTRIM(type) + '|' + CAST(include_seasonality AS char(1)) + '|' + CAST(exclude_outliers AS char(1))
	UPDATE #fitted_data SET fk = RTRIM(period) + '|' + RTRIM(type) + '|' + CAST(include_seasonality AS char(1)) + '|' + CAST(exclude_outliers AS char(1))


	-- Finally insert a "fallback" model that uses a basic weighted net additions calculation (ensures that one model is always returned)
	SET @period 	= (SELECT CASE @years WHEN 2 THEN '2-year' WHEN 3 THEN '3-year' WHEN 4 THEN '4-year' ELSE null END)

	IF (@period IS NOT null)
	BEGIN
		SET @year_4		= (SELECT CASE @years WHEN 4 THEN (SELECT MAX(DATEPART(year, date)) FROM #data) ELSE 0 END)
		SET @year_3		= (SELECT CASE @years WHEN 4 THEN @year_4 - 1 WHEN 3 THEN (SELECT MAX(DATEPART(year, date)) FROM #data) ELSE 0 END)
		SET @year_2		= (SELECT CASE @years WHEN 4 THEN @year_4 - 2 WHEN 3 THEN @year_3 - 1 WHEN 2 THEN (SELECT MAX(DATEPART(year, date)) FROM #data) ELSE 0 END)
		SET @year_1		= (SELECT CASE @years WHEN 4 THEN @year_4 - 3 WHEN 3 THEN @year_3 - 2 WHEN 2 THEN @year_2 -1 ELSE 0 END)

		SET @weight_1	= (SELECT CASE @period WHEN '2-year' THEN 0.4 WHEN '3-year' THEN 0.2 ELSE 0.1 END)
		SET @weight_2	= (SELECT CASE @period WHEN '2-year' THEN 0.6 WHEN '3-year' THEN 0.3 ELSE 0.2 END)
		SET @weight_3	= (SELECT CASE @period WHEN '3-year' THEN 0.5 WHEN '4-year' THEN 0.3 ELSE 0 END)
		SET @weight_4	= (SELECT CASE @period WHEN '4-year' THEN 0.4 ELSE 0 END)

		INSERT INTO #net_additions
		SELECT	d2.date, d.value, d2.value, d2.value - d.value, null, 0
		FROM	#data d INNER JOIN #data d2 ON d2.date = DATEADD(quarter, 1, d.date)

		UPDATE #net_additions SET value_weighted = value * @weight_1 WHERE DATEPART(year, date) = @year_1
		UPDATE #net_additions SET value_weighted = value * @weight_2 WHERE DATEPART(year, date) = @year_2
		UPDATE #net_additions SET value_weighted = value * @weight_3 WHERE DATEPART(year, date) = @year_3
		UPDATE #net_additions SET value_weighted = value * @weight_4 WHERE DATEPART(year, date) = @year_4

		-- Finally, add in the forecast quarters
		INSERT INTO #net_additions
		SELECT	dbo.excel_serial_to_datetime(x), null, null, 0, 0, 0
		FROM	@xy_forecasts

		-- Set starting value and iterate each quarter to calculate the model
		SET @value = (SELECT input FROM #net_additions WHERE date = (SELECT MIN(date) FROM #net_additions))
		SET @fk = RTRIM(@period) + '|fallback|0|0'

		WHILE EXISTS (SELECT * FROM #net_additions WHERE processed = 0)
		BEGIN
			SET @date	= (SELECT TOP 1 date FROM #net_additions WHERE processed = 0 ORDER BY date)
			SET @value	= @value + (SELECT SUM(value_weighted) FROM #net_additions WHERE DATEPART(quarter, date) = DATEPART(quarter, @date))

			INSERT INTO #fitted_data
			SELECT	@fk, @period, 0, 0, 'fallback', dbo.datetime_to_excel_serial(@date), @value, @date

			UPDATE #net_additions SET processed = 1 WHERE date = @date
		END

		INSERT INTO #fit (fk, period, include_seasonality, exclude_outliers, type, has_criteria) VALUES (@fk, @period, 0, 0, 'fallback', 1)
	END


	-- Calculate R-squared for all models (this should be more accurate even for those models where it has been computed using only the coefficients)
	UPDATE		f
	SET			f.r2 = f2.r2
	FROM		#fit f INNER JOIN
				(
					SELECT		fd.fk, 1 - SUM(SQUARE(d.value - fd.y)) / SUM(SQUARE(d.value - f.y_bar)) r2
					FROM		#fit f INNER JOIN #fitted_data fd ON f.fk = fd.fk INNER JOIN #data d ON fd.x_datetime = d.date
					WHERE		fd.x_datetime <= @last_historic_quarter
					GROUP BY	fd.fk
				) f2 ON f.fk = f2.fk

	-- Calculate MAX(ABS(variance)) as the % difference between all fitted and original values, updating the statistics tables
	UPDATE		f
	SET			f.max_variance = f2.max_variance
	FROM		#fit f INNER JOIN
				(
					SELECT		fd.fk, MAX(ABS(fd.y - d.value) / d.value) max_variance
					FROM		#fit f INNER JOIN #fitted_data fd ON f.fk = fd.fk INNER JOIN #data d ON fd.x_datetime = d.date
					WHERE		fd.x_datetime <= @last_historic_quarter
					GROUP BY	fd.fk
				) f2 ON f.fk = f2.fk

	-- Calculate the year-on-year multiplier for the predicted period versus that of the n periods preceding in the model (either 1, 2 or 3 sets of year-on-year net additions for only the quarter that matches that of @last_historic_quarter)
	UPDATE		f
	SET			f.yoy_multiplier = f2.value / f3.value
	FROM		#fit f INNER JOIN
				(
					SELECT		fd.fk, ABS((fd.y - fd2.y) / fd2.y * 100) value
					FROM		#fit f INNER JOIN #fitted_data fd ON f.fk = fd.fk INNER JOIN #fitted_data fd2 ON (fd.fk = fd2.fk AND fd.x_datetime = DATEADD(year, 1, fd2.x_datetime))
					WHERE		fd2.x_datetime = @last_historic_quarter		-- This provides the forecast year-on-year % change
				) f2 ON f.fk = f2.fk INNER JOIN
				(
					SELECT		fd.fk, AVG(ABS((fd.y - fd2.y) / fd2.y * 100)) value
					FROM		#fit f INNER JOIN #fitted_data fd ON f.fk = fd.fk INNER JOIN #fitted_data fd2 ON (fd.fk = fd2.fk AND fd.x_datetime = DATEADD(year, 1, fd2.x_datetime))
					WHERE		DATEPART(quarter, fd.x_datetime) = DATEPART(quarter, @last_historic_quarter) AND fd2.x_datetime <> @last_historic_quarter
					GROUP BY	fd.fk										-- And this provides the average of all the periods, _except_ the forecast one
				) f3 ON f.fk = f3.fk


	-- Finally score whether the model passes all of the checks for statistical fit
	-- Note: models with outliers removed are unlikely to satisfy R-squared, so exlcude them here, but return all the equivalent outlier-removed models for their counterparts that pass the criteria
	SET @r2_bar = (SELECT AVG(r2) FROM #fit)
	UPDATE #fit SET has_criteria = 1 WHERE (r2 > @r2_bar OR r2 > @min_r2) AND max_variance < @max_variance AND yoy_multiplier < @max_yoy_multiplier AND exclude_outliers = 0


	-- Fetch results
	IF @show = 1
	BEGIN
		SELECT	LEFT(fk, LEN(RTRIM(fk))-2) fk, period, type, include_seasonality, r2, max_variance, yoy_multiplier, has_criteria
		FROM	#fit
		WHERE	has_criteria = 1
		ORDER BY has_criteria DESC, r2 DESC
	END

	IF @show = 2
	BEGIN
		SELECT	RTRIM(fk) fk, period, type, x_datetime, x, y
		FROM	#fitted_data
		WHERE	LEFT(fk, LEN(RTRIM(fk))-2) IN (SELECT LEFT(fk, LEN(RTRIM(fk))-2) FROM #fit WHERE has_criteria = 1)		-- Also include outlier-removed models for the equivalent criteria passing fits
	END
END
ELSE
BEGIN
	IF @show = 1
	BEGIN
		SELECT '' fk, 'Period too short' period, 'no fit' type
	END

	IF @show = 2
	BEGIN
		SELECT	RTRIM(fk) fk, period, type, x_datetime, x, y		-- Will be empty, but return an empty set for the API view
		FROM	#fitted_data
	END
END


DROP TABLE #fitted_data
DROP TABLE #fit
DROP TABLE #net_additions
DROP TABLE #data
