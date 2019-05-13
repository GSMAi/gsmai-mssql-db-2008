
CREATE PROCEDURE [dbo].[aggregate_metric_from_zone_data]

(
	@metric_id int,
	@attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@date_spot datetime = null,
	@date_type char(1) = 'Q',
	@debug bit = 1
)

AS

DECLARE @is_decimal bit = dbo.metric_is_decimal(@metric_id)

IF @date_spot IS NULL
BEGIN
	SET @date_spot = dbo.current_reporting_quarter()
END


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit)
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit)


-- Fetch all zone values for this metric
INSERT INTO #data
SELECT	ds.id, ds.zone_id, @metric_id, @attribute_id, ds.date, ds.date_type, CASE @is_decimal WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, ds.currency_id, ds.is_spot
FROM	ds_zone_data ds INNER JOIN zones z ON ds.zone_id = z.id
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = @date_type AND ds.status_id = 3 AND z.type_id = 10


-- Global aggregation
INSERT INTO #calc
SELECT	null,
		3826,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value),
		0,
		null

FROM	#data d

GROUP BY d.metric_id, d.attribute_id, d.date, d.date_type

-- Regional aggregation
INSERT INTO #calc
SELECT	null,
		r.id,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value),
		0,
		null

FROM	#data d INNER JOIN
		zones c ON d.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN
		zones r ON zl2.zone_id = r.id

WHERE	r.id IN (SELECT DISTINCT id FROM zones WHERE type_id = 42 AND published = 1)	-- Exclude "Global" regions used only to satisfy geoscheme joins

GROUP BY r.id, d.metric_id, d.attribute_id, d.date, d.date_type

-- Subregional aggregation
INSERT INTO #calc
SELECT	null,
		s.id,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value),
		0,
		null

FROM	#data d INNER JOIN
		zones c ON d.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id

WHERE	s.id IN (SELECT DISTINCT id FROM zones WHERE type_id = 39)

GROUP BY s.id, d.metric_id, d.attribute_id, d.date, d.date_type


-- Fetch existing ids so we can UPDATE against these rows (but only where calculated, not reported)
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type AND c.currency_id = ds.currency_id)
WHERE	ds.is_calculated = 1

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN ds.val_d = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	ds.is_calculated = 1

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, created_by)
	SELECT	zone_id, metric_id, attribute_id, date, date_type, CASE @is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, 6, 194, 1, is_spot, 11770
	FROM	#calc
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	--SELECT * FROM #data
	SELECT * FROM #calc
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: aggregate_metric_from_zone_data (31s)'

DROP TABLE #calc
DROP TABLE #data
