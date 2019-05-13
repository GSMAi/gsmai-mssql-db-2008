
CREATE PROCEDURE [dbo].[calculate_opex]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit
SET @is_decimal = dbo.metric_is_decimal(65)

-- Calculation table; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(32,8), currency_id int, is_calculated bit, source_id int, confidence_id int, calc_value decimal(32,8), calc_currency_id int, calc_value_2 decimal(32,8), calc_currency_id_2 int, currency_rate decimal(32,8), calc_currency_rate decimal(32,8), calc_currency_rate_2 decimal(32,8), processed bit)

-- Get all data points for these mixed metrics as a reference set
INSERT INTO #calc
SELECT	DISTINCT null, ds.organisation_id, null, null, ds.date, ds.date_type, null, null, 0, null, null, null, null, null, null, null, null, null, 0
FROM	ds_organisation_data ds
WHERE	ds.metric_id IN (18,29,65) AND ds.attribute_id = 0 AND ds.date >= @date_start AND ds.date < @date_end

-- Update with corresponding opex data points
UPDATE	c
SET		c.id = ds.id, c.metric_id = ds.metric_id, c.attribute_id = ds.attribute_id, c.value = CASE WHEN ds.val_d IS null THEN CAST(ds.val_i AS decimal(32,8)) ELSE ds.val_d END, c.currency_id = ds.currency_id, c.is_calculated = ds.is_calculated, c.source_id = ds.source_id, c.confidence_id = ds.confidence_id
FROM	ds_organisation_data ds INNER JOIN #calc c ON (ds.organisation_id = c.organisation_id AND ds.date = c.date AND ds.date_type = c.date_type)
WHERE	ds.metric_id = 65 AND ds.attribute_id = 0

-- Update with corresponding revenue data points
UPDATE	c
SET		c.calc_value = CASE WHEN ds.val_d IS null THEN CAST(ds.val_i AS decimal(32,8)) ELSE ds.val_d END, c.calc_currency_id = ds.currency_id
FROM	ds_organisation_data ds INNER JOIN #calc c ON (ds.organisation_id = c.organisation_id AND ds.date = c.date AND ds.date_type = c.date_type)
WHERE	ds.metric_id = 18 AND ds.attribute_id = 0

-- Update with corresponding EBITDA data points
UPDATE	c
SET		c.calc_value_2 = CASE WHEN ds.val_d IS null THEN CAST(ds.val_i AS decimal(32,8)) ELSE ds.val_d END, c.calc_currency_id_2 = ds.currency_id
FROM	ds_organisation_data ds INNER JOIN #calc c ON (ds.organisation_id = c.organisation_id AND ds.date = c.date AND ds.date_type = c.date_type)
WHERE	ds.metric_id = 29 AND ds.attribute_id = 0


-- Get the exchange rate conversion if revenue is reported in a different currency to EBITDA
UPDATE #calc SET currency_rate = 1 WHERE calc_currency_id = calc_currency_id_2

UPDATE	c
SET		c.calc_currency_id = cr.value, c.calc_currency_id_2 = cr2.value
FROM	#calc c INNER JOIN currency_rates cr ON (c.calc_currency_id = cr.from_currency_id AND cr.to_currency_id = 2 AND c.date = cr.date AND c.date_type = cr.date_type) INNER JOIN currency_rates cr2 ON (c.calc_currency_id_2 = cr2.from_currency_id AND cr2.to_currency_id = 2 AND c.date = cr2.date AND c.date_type = cr2.date_type)
WHERE	c.calc_currency_id <> c.calc_currency_id_2

-- Since we don't hold every relationship between currencies, simply use the ratio of conversions between USD
UPDATE #calc SET currency_rate = calc_currency_rate_2 / calc_currency_rate WHERE calc_currency_id <> calc_currency_id_2


-- Update _calculated_ values, leaving reported values untouched
UPDATE	c
SET		c.value = c.calc_value - (c.calc_value_2 * c.currency_rate), c.currency_id = c.calc_currency_id, c.is_calculated = 1, c.source_id = 6, c.confidence_id = 194
FROM	#calc c
WHERE	(c.is_calculated = 1 OR c.is_calculated IS null) AND c.calc_value IS NOT null AND c.calc_value_2 IS NOT null

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the _calculated_ values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.currency_id = c.currency_id, ds.is_calculated = c.is_calculated, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.last_update_on = CASE WHEN CAST(ds.val_i AS decimal(32,8)) = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN CAST(ds.val_i AS decimal(32,8)) = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1 AND c.value IS NOT null

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	c.organisation_id, c.metric_id, c.attribute_id, c.date, c.date_type, CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, c.currency_id, c.source_id, c.confidence_id, 1, 11770
	FROM	#calc c
	WHERE	c.id IS null AND c.value IS NOT null
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY organisation_id, date_type, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_opex (3s)'

DROP TABLE #calc
