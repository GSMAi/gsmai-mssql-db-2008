
CREATE PROCEDURE [dbo].[aggregate_metric_by_division]

(
	@metric_id int,
	@attribute_id int,
	@dividend_metric_id int,
	@dividend_attribute_id int,
	@divisor_metric_id int,			-- TODO: Assuming a non-financial metric
	@divisor_attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@date_type_factor decimal(26,8) = 3,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit, @dividend_is_decimal bit, @divisor_is_decimal bit, @currency_id int, @is_spot bit

SET @is_decimal 			= dbo.metric_is_decimal(@metric_id)
SET @dividend_is_decimal	= dbo.metric_is_decimal(@dividend_metric_id)
SET @divisor_is_decimal		= dbo.metric_is_decimal(@divisor_metric_id)


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(26,8), currency_id int, is_spot bit, is_calculated bit, dividend_value decimal(26,8), divisor_value decimal(26,8))


-- Fetch all values for the dividend and divisor metrics (note will be x4 x2 rows per financial data point)
BEGIN TRY
	INSERT INTO #calc
	SELECT	null, ds.zone_id, @metric_id, @attribute_id, ds.date, ds.date_type, null, ds.currency_id, ds.is_spot, null, CASE @dividend_is_decimal WHEN 1 THEN ds.val_d ELSE ds.val_i END, null
	FROM	ds_zone_data ds
	WHERE	ds.metric_id = @dividend_metric_id AND ds.attribute_id = @dividend_attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = @date_type AND ds.status_id = 3
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'INSERT INTO #calc .... FROM ds_zone_data'
END CATCH

BEGIN TRY
	UPDATE	c
	SET		c.divisor_value = CASE @divisor_is_decimal WHEN 1 THEN ds.val_d ELSE ds.val_i END
	FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.date = ds.date AND c.date_type = ds.date_type) -- TODO: ignoring currency as assumed linking a non-financial metric
	WHERE	ds.metric_id = @divisor_metric_id AND ds.attribute_id = @divisor_attribute_id AND ds.status_id = 3
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'UPDATE	c ... FROM	#calc c'
END CATCH


-- Divide through to calculate the derived metric
BEGIN TRY
	UPDATE	c
	SET		c.value = c.dividend_value / (CASE WHEN c2.divisor_value IS null THEN c.divisor_value ELSE (c.divisor_value + c2.divisor_value) / 2 END) / @date_type_factor
	FROM	#calc c LEFT JOIN #calc c2 ON (c.zone_id = c2.zone_id AND c.date = DATEADD(month, @date_type_factor, c2.date) AND c.date_type = c2.date_type AND c.currency_id = c2.currency_id AND c.is_spot = c2.is_spot)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'Divide through to calculate the derived metric'
END CATCH


-- Fetch existing ids so we can UPDATE against these rows (but only where calculated, not reported)
BEGIN TRY
	UPDATE	c
	SET		c.id = ds.id, c.is_calculated = ds.is_calculated
	FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type AND c.currency_id = ds.currency_id AND c.is_spot = ds.is_spot)
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'Fetch existing ids so we can UPDATE against these rows (but only where calculated, not reported)'
END CATCH

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null OR value = 0


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	BEGIN TRY
		UPDATE	ds
		SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
		FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
		WHERE	ds.is_calculated = 1
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_errors] @query_string = 'UPDATE	ds'
	END CATCH

	-- INSERT the remainder
	BEGIN TRY
		INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, created_by)
		SELECT	zone_id, metric_id, attribute_id, date, date_type, CASE @is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, 6, 194, 1, is_spot, 11770
		FROM	#calc
		WHERE	id IS null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_errors] @query_string = 'INSERT INTO ds_zone_data'
	END CATCH

END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY zone_id, date_type, date, is_spot, currency_id
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: aggregate_metric_by_division (4s)'

DROP TABLE #calc
