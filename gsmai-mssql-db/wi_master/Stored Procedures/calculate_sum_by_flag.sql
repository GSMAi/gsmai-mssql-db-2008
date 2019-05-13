
CREATE PROCEDURE [dbo].[calculate_sum_by_flag]

(
	@metric_id int,				-- Output metric.id
	@attribute_id int,			-- Output attribute.id
	@metric_id_2 int,			-- Input metric.id
	@attribute_id_2 int,		-- Input attribute.id
	@metric_id_3 int,			-- Input metric.id
	@attribute_id_3 int,		-- Input attribute.id
	@flag_id int,				-- Flag indicates _inclusive_ data
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@debug bit = 1
)

AS

DECLARE @is_decimal bit = dbo.metric_is_decimal(@metric_id)
DECLARE @is_decimal_2 bit = dbo.metric_is_decimal(@metric_id_2)
DECLARE @is_decimal_3 bit = dbo.metric_is_decimal(@metric_id_3)

DECLARE @is_currency_based bit = dbo.metric_is_currency_based(@metric_id)

-- Calculation tables
CREATE TABLE #data (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int, id_2 bigint, metric_id_2 int, attribute_id_2 int, value_2 decimal(22,8), currency_id_2 int, source_id_2 int, confidence_id_2 int, currency_rate decimal(22,8), has_flag bit)
CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int, is_calculated bit, processed bit)

-- Collect all operator figures for both input metrics
INSERT INTO #data
SELECT	DISTINCT
		null,
		ds.organisation_id,
		@metric_id_2,
		@attribute_id_2,
		ds.date,
		ds.date_type,
		null,
		null,
		null,
		null,
		null,
		@metric_id_3,
		@attribute_id_3,
		null,
		null,
		null,
		null,
		null,
		0
		
FROM	ds_organisation_data ds INNER JOIN
		organisations o ON ds.organisation_id = o.id

WHERE	(
			(ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2) OR
			(ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3)
		) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type = @date_type AND
		ds.status_id = 3 AND
		o.type_id = 1089
		
ORDER BY ds.organisation_id, ds.date_type, ds.date

UPDATE	d
SET		d.id = ds.id, d.value = CASE @is_decimal_2 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id = ds.currency_id, d.source_id = ds.source_id, d.confidence_id = ds.confidence_id
FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.organisation_id = d.organisation_id AND ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2

UPDATE	d
SET		d.id_2 = ds.id, d.value_2 = CASE @is_decimal_3 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id_2 = ds.currency_id, d.source_id_2 = ds.source_id, d.confidence_id_2 = ds.confidence_id
FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.organisation_id = d.organisation_id AND ds.metric_id = d.metric_id_2 AND ds.attribute_id = d.attribute_id_2 AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3


-- Get the exchange rate conversion if @metric_id_2 is reported in a different currency to @metric_id_3, using a common intermediary currency
UPDATE	d
SET		d.currency_rate = CASE cr.value WHEN 0 THEN 0 ELSE cr2.value/cr.value END
FROM	#data d INNER JOIN currency_rates cr ON (d.currency_id = cr.from_currency_id AND cr.to_currency_id = 2 AND d.date = cr.date AND d.date_type = cr.date_type) INNER JOIN currency_rates cr2 ON (d.currency_id_2 = cr2.from_currency_id AND cr2.to_currency_id = 2 AND d.date = cr2.date AND d.date_type = cr2.date_type)
WHERE	d.currency_id <> d.currency_id_2 AND d.currency_id <> 0 AND d.currency_id_2 <> 0

-- Else, we can divide the data as-reported
UPDATE	#data SET currency_rate = 1 WHERE currency_rate IS null


-- Update with all operator flags
UPDATE	d
SET		d.has_flag = 1
FROM	flag_organisation_link fo INNER JOIN #data d ON fo.organisation_id = d.organisation_id
WHERE	fo.flag_id = @flag_id

UPDATE #data SET has_flag = 0 WHERE has_flag IS null


-- Update missing values, source and confidence
UPDATE #data SET value_2 = 0 WHERE value_2 IS null
UPDATE #data SET currency_id_2 = currency_id WHERE currency_id_2 IS null
UPDATE #data SET source_id_2 = source_id WHERE source_id_2 IS null
UPDATE #data SET confidence_id_2 = confidence_id WHERE confidence_id_2 IS null


-- Calculate sum based on values, flag
INSERT INTO #calc
SELECT	null,
		d.organisation_id,
		@metric_id,
		@attribute_id,
		d.date,
		d.date_type,
		CASE d.has_flag WHEN 0 THEN d.value + (d.value_2 * d.currency_rate) ELSE d.value END,
		CASE @is_currency_based WHEN 1 THEN d.currency_id ELSE 0 END,
		CASE WHEN d.source_id < d.source_id_2 THEN d.source_id ELSE d.source_id_2 END, -- MIN() only works over columns
		CASE WHEN d.confidence_id > d.confidence_id_2 THEN d.confidence_id ELSE d.confidence_id_2 END, -- MAX() only works over columns
		1,
		0

FROM	#data d

ORDER BY d.organisation_id, d.date_type, d.date

-- Update with corresponding existing data points
UPDATE	c
SET		c.id = ds.id, c.is_calculated = ds.is_calculated
FROM	ds_organisation_data ds INNER JOIN #calc c ON (ds.organisation_id = c.organisation_id AND ds.metric_id = c.metric_id AND ds.attribute_id = c.attribute_id AND ds.date = c.date AND ds.date_type = c.date_type)
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id


-- Remove any NULL data
--DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the _calculated_ values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.currency_id = c.currency_id, ds.is_calculated = c.is_calculated, ds.source_id = c.source_id, ds.confidence_id = c.confidence_id, ds.last_update_on = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN CAST(ds.val_i AS decimal(22,8)) = c.value THEN ds.last_update_by ELSE 11770 END
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
SELECT 'Finished: calculate_sum_by_flag (11s)'

DROP TABLE #data
DROP TABLE #calc
