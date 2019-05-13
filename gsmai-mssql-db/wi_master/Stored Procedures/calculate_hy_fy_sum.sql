
CREATE PROCEDURE [dbo].[calculate_hy_fy_sum]

(
	@metric_id int,
	@attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit, @is_currency_based bit, @currency_id int, @is_spot bit

SET @is_decimal = dbo.metric_is_decimal(@metric_id)
SET @is_currency_based = dbo.metric_is_currency_based(@metric_id)


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, period_ending_currency_id int, rate decimal(22,8), source_id int, confidence_id int)
CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int)


-- Fetch all quarterly operator values for this metric
INSERT INTO #data
SELECT	ds.id, ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, CASE @is_decimal WHEN 1 THEN ds.val_d ELSE ds.val_i END, ds.currency_id, null, 1, ds.source_id, ds.confidence_id
FROM	ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = 'Q' AND ds.status_id = 3 AND o.type_id = 1089


-- Normalise currencies that switch mid-half
UPDATE	d
SET		d.period_ending_currency_id = d2.currency_id
FROM	#data d INNER JOIN
		#data d2 ON (d.organisation_id = d2.organisation_id AND d.metric_id = d2.metric_id AND d.attribute_id = d2.attribute_id AND DATEPART(year, d.date) = DATEPART(year, d2.date) AND CASE DATEPART(month, d.date) WHEN 1 THEN 0 WHEN 4 THEN 0 ELSE 1 END = CASE DATEPART(month, d2.date) WHEN 1 THEN 0 WHEN 4 THEN 0 ELSE 1 END)
WHERE	DATEPART(month, d2.date) IN (4,10)

UPDATE #data SET rate = 1
UPDATE #data SET period_ending_currency_id = currency_id WHERE period_ending_currency_id IS null

IF @is_currency_based = 1
BEGIN
	UPDATE	d
	SET		d.rate = cr.value / cr2.value
	FROM	#data d INNER JOIN
			currency_rates cr ON (d.currency_id = cr.from_currency_id AND d.date = cr.date AND d.date_type = cr.date_type) INNER JOIN
			currency_rates cr2 ON (d.period_ending_currency_id = cr2.from_currency_id AND d.date = cr.date AND d.date_type = cr.date_type AND cr.to_currency_id = cr2.to_currency_id)
	WHERE	d.currency_id <> d.period_ending_currency_id AND cr.to_currency_id = 2
END

-- Calculate HY sums
INSERT INTO #calc
SELECT	null, d.organisation_id, d.metric_id, d.attribute_id, MIN(d.date), 'H', SUM(d.value * d.rate), d.period_ending_currency_id, MIN(d.source_id), MAX(d.confidence_id) 	-- Will produce 2000-01-01 and 2000-07-01
FROM	#data d
GROUP BY d.organisation_id, d.metric_id, d.attribute_id, DATEPART(year, d.date), CASE DATEPART(month, d.date) WHEN 1 THEN 0 WHEN 4 THEN 0 ELSE 1 END, d.period_ending_currency_id


-- Normalise currencies that switch mid-year
UPDATE	d
SET		d.period_ending_currency_id = d2.currency_id
FROM	#data d INNER JOIN
		#data d2 ON (d.organisation_id = d2.organisation_id AND d.metric_id = d2.metric_id AND d.attribute_id = d2.attribute_id AND DATEPART(year, d.date) = DATEPART(year, d2.date))
WHERE	DATEPART(month, d2.date) = 10

UPDATE #data SET rate = 1
UPDATE #data SET period_ending_currency_id = currency_id WHERE period_ending_currency_id IS null

IF @is_currency_based = 1
BEGIN
	UPDATE	d
	SET		d.rate = cr.value / cr2.value
	FROM	#data d INNER JOIN
			currency_rates cr ON (d.currency_id = cr.from_currency_id AND d.date = cr.date AND d.date_type = cr.date_type) INNER JOIN
			currency_rates cr2 ON (d.period_ending_currency_id = cr2.from_currency_id AND d.date = cr.date AND d.date_type = cr.date_type AND cr.to_currency_id = cr2.to_currency_id)
	WHERE	d.currency_id <> d.period_ending_currency_id AND cr.to_currency_id = 2
END

-- Calculate FY sums
INSERT INTO #calc
SELECT	null, d.organisation_id, d.metric_id, d.attribute_id, MIN(d.date), 'Y', SUM(d.value * d.rate), d.period_ending_currency_id, MIN(d.source_id), MAX(d.confidence_id)	-- Will produce 2000-01-01
FROM	#data d
GROUP BY d.organisation_id, d.metric_id, d.attribute_id, DATEPART(year, d.date), d.period_ending_currency_id


-- Update HY and FY dates where quarterly data doesn't start until Q2/Q4, throwing off MIN(d.date)
UPDATE #calc SET date = CAST(CAST(DATEPART(year, date) AS varchar) + '-01-01' AS datetime) WHERE date_type = 'H' AND DATEPART(month, date) = 4
UPDATE #calc SET date = CAST(CAST(DATEPART(year, date) AS varchar) + '-07-01' AS datetime) WHERE date_type = 'H' AND DATEPART(month, date) = 10
UPDATE #calc SET date = CAST(CAST(DATEPART(year, date) AS varchar) + '-01-01' AS datetime) WHERE date_type = 'Y' AND DATEPART(month, date) <> 1


-- Fetch existing ids so we can UPDATE against these rows (but only where calculated, not reported)
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_organisation_data ds ON (c.organisation_id = ds.organisation_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.currency_id = c.currency_id, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.last_update_on = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	organisation_id, metric_id, attribute_id, date, date_type, CASE @is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, source_id, confidence_id, 1, 11770
	FROM	#calc
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	--SELECT * FROM #data
	SELECT * FROM #calc
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_hy_fy_sum (19s)'

DROP TABLE #calc
DROP TABLE #data
