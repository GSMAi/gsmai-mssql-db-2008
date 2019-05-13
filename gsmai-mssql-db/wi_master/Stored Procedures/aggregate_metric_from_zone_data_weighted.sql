
CREATE PROCEDURE [dbo].[aggregate_metric_from_zone_data_weighted]

(
	@metric_id int,
	@attribute_id int,
	@weighting_metric_id int,
	@weighting_attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@date_spot datetime = null,
	@date_type char(1) = 'Q',
	@threshold float = 0.5,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit, @weighting_is_decimal bit, @weighting_is_currency_based bit

SET @is_decimal = dbo.metric_is_decimal(@metric_id)
SET @weighting_is_decimal = dbo.metric_is_decimal(@weighting_metric_id)
SET @weighting_is_currency_based = dbo.metric_is_currency_based(@weighting_metric_id)

IF @date_spot IS NULL
BEGIN
	SET @date_spot = dbo.current_reporting_quarter()
END


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit, weighting_value decimal(22,8), connections_value decimal(22,8))
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,8), currency_id int, is_spot bit, weight decimal(22,8))


-- Fetch all zone values for total connections (to ensure a complete set), the metric and the weighting metric (spot currency normalisation, if applicable)
INSERT INTO #data
SELECT	null, ds.zone_id, @metric_id, @attribute_id, ds.date, ds.date_type, null, null, null, null, ds.val_i
FROM	ds_zone_data ds INNER JOIN zones z ON ds.zone_id = z.id
WHERE	ds.metric_id = 3 AND ds.attribute_id = 0 AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = @date_type AND ds.status_id = 3 AND z.type_id = 10

UPDATE	d
SET		d.id = ds.id, d.value = CASE @is_decimal WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END, d.currency_id = ds.currency_id, d.is_spot = ds.is_spot
FROM	#data d INNER JOIN ds_zone_data ds ON (d.zone_id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = @date_type AND ds.status_id = 3

IF @weighting_is_currency_based = 1
BEGIN
	UPDATE	d
	SET		d.weighting_value = CASE @weighting_is_decimal WHEN 1 THEN ds.val_d * cr.value ELSE CAST(ds.val_i * cr.value AS decimal(22,8)) END
	FROM	#data d INNER JOIN ds_zone_data ds ON (d.zone_id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN currency_rates cr ON (ds.currency_id = cr.from_currency_id)
	WHERE	ds.metric_id = @weighting_metric_id AND ds.attribute_id = @weighting_attribute_id AND ds.status_id = 3 AND cr.to_currency_id = 1 AND cr.date = @date_spot
END
ELSE
BEGIN
	UPDATE	d
	SET		d.weighting_value = CASE @weighting_is_decimal WHEN 1 THEN ds.val_d ELSE CAST(ds.val_i AS decimal(22,8)) END
	FROM	#data d INNER JOIN ds_zone_data ds ON (d.zone_id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type)
	WHERE	ds.metric_id = @weighting_metric_id AND ds.attribute_id = @weighting_attribute_id AND ds.status_id = 3
END

-- Nullify connections where no metric value exists to get an accurate reported threshold
UPDATE #data SET connections_value = null WHERE value IS null


-- Global aggregation
INSERT INTO #calc
SELECT	null,
		ds.zone_id,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value * d.weighting_value / d2.weighting_sum),
		0,
		null,
		SUM(d.connections_value) / ds.val_i

FROM	#data d INNER JOIN
		ds_zone_data ds ON (d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
		(
			SELECT	SUM(d.weighting_value) weighting_sum, d.date, d.date_type
			FROM	#data d
			GROUP BY d.date, d.date_type
		) d2 ON (d.date = d2.date AND d.date_type = d2.date_type)

WHERE	ds.zone_id = 3826 AND
		ds.metric_id = 3 AND
		ds.attribute_id = 0

GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

-- Regional aggregation
INSERT INTO #calc
SELECT	null,
		ds.zone_id,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value * d.weighting_value / d2.weighting_sum),
		0,
		null,
		SUM(d.connections_value) / ds.val_i

FROM	#data d INNER JOIN
		zones c ON d.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN
		zones r ON zl2.zone_id = r.id INNER JOIN
		ds_zone_data ds ON (r.id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
		(
			SELECT	r.id zone_id, SUM(d.weighting_value) weighting_sum, d.date, d.date_type
			FROM	#data d INNER JOIN zone_link zl ON d.zone_id = zl.subzone_id INNER JOIN zone_link zl2 ON zl.zone_id = zl2.subzone_id INNER JOIN zones r ON zl2.zone_id = r.id
			GROUP BY r.id, d.date, d.date_type
		) d2 ON (r.id = d2.zone_id AND d.date = d2.date AND d.date_type = d2.date_type)

WHERE	ds.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id = 42 AND published = 1) AND	-- Exclude "Global" regions used only to satisfy geoscheme joins
		ds.metric_id = 3 AND
		ds.attribute_id = 0

GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

-- Subregional aggregation
INSERT INTO #calc
SELECT	null,
		ds.zone_id,
		d.metric_id,
		d.attribute_id,
		d.date,
		d.date_type,
		SUM(d.value * d.weighting_value / d2.weighting_sum),
		0,
		null,
		SUM(d.connections_value) / ds.val_i

FROM	#data d INNER JOIN
		zones c ON d.zone_id = c.id INNER JOIN
		zone_link zl ON c.id = zl.subzone_id INNER JOIN
		zones s ON zl.zone_id = s.id INNER JOIN
		ds_zone_data ds ON (s.id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
		(
			SELECT	s.id zone_id, SUM(d.weighting_value) weighting_sum, d.date, d.date_type
			FROM	#data d INNER JOIN zone_link zl ON d.zone_id = zl.subzone_id INNER JOIN zones s ON zl.zone_id = s.id
			GROUP BY s.id, d.date, d.date_type
		) d2 ON (s.id = d2.zone_id AND d.date = d2.date AND d.date_type = d2.date_type)

WHERE	ds.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id = 39) AND
		ds.metric_id = 3 AND
		ds.attribute_id = 0

GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i


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
	WHERE	ds.is_calculated = 1 AND c.weight >= @threshold

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, created_by)
	SELECT	zone_id, metric_id, attribute_id, date, date_type, CASE @is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE @is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, currency_id, 6, 194, 1, is_spot, 11770
	FROM	#calc
	WHERE	id IS null AND weight >= @threshold
END

IF @debug = 1
BEGIN
	--SELECT * FROM #data
	SELECT * FROM #calc
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: aggregate_metric_from_zone_data_weighted (31s)'

DROP TABLE #calc
DROP TABLE #data
