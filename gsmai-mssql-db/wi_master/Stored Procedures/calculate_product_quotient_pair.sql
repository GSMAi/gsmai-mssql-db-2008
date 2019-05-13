﻿
CREATE PROCEDURE [dbo].[calculate_product_quotient_pair]

(
	@metric_id int,					-- Output metric.id
	@attribute_id int,				-- Output attribute.id
	@metric_id_2 int,				-- Output metric.id
	@attribute_id_2 int,			-- Output attribute.id
	@metric_id_3 int,				-- Input metric.id, typically used as a weighting multiplier/divisor
	@attribute_id_3 int,			-- Input attribute.id
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@periodicity_factor int = 3,	-- A periodicity multiple that converts between @metric_id and @metric_id_2 (eg a monthly metric has a periodicty factor of 3 to scale to quarterly)
	@debug bit = 1
)

AS

DECLARE @is_decimal bit = dbo.metric_is_decimal(@metric_id)
DECLARE @is_decimal_2 bit = dbo.metric_is_decimal(@metric_id_2)
DECLARE @is_decimal_3 bit = dbo.metric_is_decimal(@metric_id_3)

-- Calculation tables
CREATE TABLE #data (id bigint, organisation_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, metric_id int, attribute_id int, value decimal(22,8), currency_id int, source_id int, confidence_id int, is_calculated bit, id_2 bigint, metric_id_2 int, attribute_id_2 int, value_2 decimal(22,8), currency_id_2 int, source_id_2 int, confidence_id_2 int, is_calculated_2 bit, id_3 bigint, metric_id_3 int, attribute_id_3 int, value_3 decimal(22,8), currency_id_3 int, source_id_3 int, confidence_id_3 int)
CREATE TABLE #calc (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, source_id int, confidence_id int, is_calculated bit, processed bit)

-- Collect all operator figures for both input metrics
INSERT INTO #data
SELECT	DISTINCT
		null,
		ds.organisation_id,
		ds.date,
		ds.date_type,
		@metric_id,
		@attribute_id,
		null,
		null,
		null,
		null,
		null,
		null,
		@metric_id_2,
		@attribute_id_2,
		null,
		null,
		null,
		null,
		null,
		null,
		@metric_id_3 int,
		@attribute_id_3 int,
		null,
		null,
		null,
		null
		
FROM	ds_organisation_data ds INNER JOIN
		organisations o ON ds.organisation_id = o.id

WHERE	(
			(ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id) OR
			(ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2)
		) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type = @date_type AND
		ds.status_id = 3 AND
		o.type_id = 1089
		
ORDER BY ds.organisation_id, ds.date_type, ds.date

UPDATE	d
SET		d.id = ds.id, d.value = CASE @is_decimal WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id = ds.currency_id, d.source_id = ds.source_id, d.confidence_id = ds.confidence_id, d.is_calculated = ds.is_calculated
FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.organisation_id = d.organisation_id AND ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id

UPDATE	d
SET		d.id_2 = ds.id, d.value_2 = CASE @is_decimal_2 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id_2 = ds.currency_id, d.source_id_2 = ds.source_id, d.confidence_id_2 = ds.confidence_id, d.is_calculated_2 = ds.is_calculated
FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.organisation_id = d.organisation_id AND ds.metric_id = d.metric_id_2 AND ds.attribute_id = d.attribute_id_2 AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	ds.metric_id = @metric_id_2 AND ds.attribute_id = @attribute_id_2

UPDATE	d
SET		d.id_3 = ds.id, d.value_3 = CASE @is_decimal_3 WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id_3 = ds.currency_id, d.source_id_3 = ds.source_id, d.confidence_id_3 = ds.confidence_id
FROM	ds_organisation_data ds INNER JOIN #data d ON (ds.organisation_id = d.organisation_id AND ds.metric_id = d.metric_id_3 AND ds.attribute_id = d.attribute_id_3 AND ds.date = d.date AND ds.date_type = d.date_type)
WHERE	ds.metric_id = @metric_id_3 AND ds.attribute_id = @attribute_id_3


-- TODO: exchange rate conversion if @metric_id is reported in a different currency to @metric_id_2? Is this ever needed?


-- (Re-)calculate missing products and quotients based on values
INSERT INTO #calc
SELECT	d.id,
		d.organisation_id,
		@metric_id,
		@attribute_id,
		d.date,
		d.date_type,
		d.value_2 * d.value_3 * @periodicity_factor,
		d.currency_id_2,
		CASE WHEN d.source_id_2 < d.source_id_3 THEN d.source_id_2 ELSE d.source_id_3 END, -- MIN() only works over columns
		CASE WHEN d.confidence_id_2 > d.confidence_id_3 THEN d.confidence_id_2 ELSE d.confidence_id_3 END, -- MAX() only works over columns
		1,
		0

FROM	#data d

WHERE	d.value IS null OR
		d.is_calculated = 1

ORDER BY d.organisation_id, d.date_type, d.date

INSERT INTO #calc
SELECT	d.id_2,
		d.organisation_id,
		@metric_id_2,
		@attribute_id_2,
		d.date,
		d.date_type,
		d.value / d.value_3 / @periodicity_factor,
		d.currency_id_2,
		CASE WHEN d.source_id < d.source_id_3 THEN d.source_id ELSE d.source_id_3 END, -- MIN() only works over columns
		CASE WHEN d.confidence_id > d.confidence_id_3 THEN d.confidence_id ELSE d.confidence_id_3 END, -- MAX() only works over columns
		1,
		0

FROM	#data d

WHERE	d.value_2 IS null OR
		d.is_calculated_2 = 1

ORDER BY d.organisation_id, d.date_type, d.date


-- Remove any empty data
DELETE FROM #calc WHERE value IS null OR value = 0


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
	SELECT * FROM #data ORDER BY organisation_id, date_type, date
	SELECT * FROM #calc ORDER BY organisation_id, date_type, date
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: calculate_product_quotient_pair (11s)'

DROP TABLE #data
DROP TABLE #calc
