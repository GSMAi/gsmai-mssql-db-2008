﻿

CREATE PROCEDURE [dbo].[aggregate_summed_currency_based_metric]

(
	@metric_id int,
	@attribute_id int,
	@date_start datetime,
	@date_end datetime,
	@date_spot datetime = null,
	@date_type char(1) = 'Q',
	@threshold float = 0.0,
	@debug bit = 1
)

AS

DECLARE @is_decimal bit, @currency_id int, @is_spot bit

SET @is_decimal = dbo.metric_is_decimal(@metric_id)

IF @date_spot IS NULL
BEGIN
	SET @date_spot = dbo.current_reporting_quarter()
END


-- Calculation tables; use twice the precision as the final stored value to allow for accuracy when converting currencies
CREATE TABLE #data (id bigint, organisation_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6), currency_id int, connections_value decimal(22,6))
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6), currency_id int, is_spot bit, weight decimal(22,6))


-- Fetch all operator values for this metric and total connections
INSERT INTO #data
SELECT	ds.id, ds.organisation_id, ds.metric_id, ds.attribute_id, ds.date, ds.date_type, CASE @is_decimal WHEN 1 THEN ds.val_d ELSE ds.val_i END, ds.currency_id, null
FROM	ds_organisation_data ds INNER JOIN organisations o ON ds.organisation_id = o.id
WHERE	ds.metric_id = @metric_id AND ds.attribute_id = @attribute_id AND ds.date >= @date_start AND ds.date < @date_end AND ds.date_type = @date_type AND ds.status_id = 3 AND o.type_id = 1089

UPDATE	d
SET		d.connections_value = ds.val_i
FROM	#data d INNER JOIN ds_organisation_data ds ON (d.organisation_id = ds.organisation_id AND d.date = ds.date AND d.date_type = ds.date_type)
WHERE	ds.metric_id = 3 AND ds.attribute_id = 0 AND ds.status_id = 3


-- Currencies to calculate
CREATE TABLE #currencies (id int, is_spot bit, processed bit)

INSERT INTO #currencies
SELECT id, 0, 0 FROM currencies WHERE id IN (1,2,3,73) UNION ALL
SELECT id, 1, 0 FROM currencies WHERE id IN (1,2,3,73)


WHILE EXISTS (SELECT * FROM #currencies WHERE processed = 0)
BEGIN
	SET @currency_id 	= (SELECT TOP 1 id FROM #currencies WHERE processed = 0)
	SET @is_spot		= (SELECT TOP 1 is_spot FROM #currencies WHERE id = @currency_id AND processed = 0)

	-- Global aggregation
	INSERT INTO #calc
	SELECT	null,
			ds.zone_id,
			d.metric_id,
			d.attribute_id,
			d.date,
			d.date_type,
			SUM(d.value * cr.value),
			@currency_id,
			@is_spot,
			SUM(d.connections_value) / ds.val_i

	FROM	#data d INNER JOIN
			ds_zone_data ds ON (d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
			currency_rates cr ON (cr.from_currency_id = d.currency_id AND cr.to_currency_id = @currency_id)

	WHERE	ds.zone_id = 3826 AND
			ds.metric_id = 3 AND
			ds.attribute_id = 0 AND
			(
				(@is_spot = 0 AND cr.date = d.date) OR
				(@is_spot = 1 AND cr.date = @date_spot)
			)

	GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

	-- Regional aggregation
	INSERT INTO #calc
	SELECT	null,
			ds.zone_id,
			d.metric_id,
			d.attribute_id,
			d.date,
			d.date_type,
			SUM(d.value * cr.value),
			@currency_id,
			@is_spot,
			SUM(d.connections_value) / ds.val_i

	FROM	#data d INNER JOIN
			organisation_zone_link oz ON d.organisation_id = oz.organisation_id INNER JOIN
			zones c ON oz.zone_id = c.id INNER JOIN
			zone_link zl ON c.id = zl.subzone_id INNER JOIN
			zones s ON zl.zone_id = s.id INNER JOIN
			zone_link zl2 ON s.id = zl2.subzone_id INNER JOIN
			zones r ON zl2.zone_id = r.id INNER JOIN
			ds_zone_data ds ON (r.id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
			currency_rates cr ON (cr.from_currency_id = d.currency_id AND cr.to_currency_id = @currency_id)

	WHERE	ds.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id = 42) AND
			ds.metric_id = 3 AND
			ds.attribute_id = 0 AND
			(
				(@is_spot = 0 AND cr.date = d.date) OR
				(@is_spot = 1 AND cr.date = @date_spot)
			)

	GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

	-- Subregional aggregation
	INSERT INTO #calc
	SELECT	null,
			ds.zone_id,
			d.metric_id,
			d.attribute_id,
			d.date,
			d.date_type,
			SUM(d.value * cr.value),
			@currency_id,
			@is_spot,
			SUM(d.connections_value) / ds.val_i

	FROM	#data d INNER JOIN
			organisation_zone_link oz ON d.organisation_id = oz.organisation_id INNER JOIN
			zones c ON oz.zone_id = c.id INNER JOIN
			zone_link zl ON c.id = zl.subzone_id INNER JOIN
			zones s ON zl.zone_id = s.id INNER JOIN
			ds_zone_data ds ON (s.id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
			currency_rates cr ON (cr.from_currency_id = d.currency_id AND cr.to_currency_id = @currency_id)

	WHERE	ds.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id = 39) AND
			ds.metric_id = 3 AND
			ds.attribute_id = 0 AND
			(
				(@is_spot = 0 AND cr.date = d.date) OR
				(@is_spot = 1 AND cr.date = @date_spot)
			)

	GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

	-- Country aggregation
	INSERT INTO #calc
	SELECT	null,
			ds.zone_id,
			d.metric_id,
			d.attribute_id,
			d.date,
			d.date_type,
			SUM(d.value * cr.value),
			@currency_id,
			@is_spot,
			SUM(d.connections_value) / ds.val_i

	FROM	#data d INNER JOIN
			organisation_zone_link oz ON d.organisation_id = oz.organisation_id INNER JOIN
			zones c ON oz.zone_id = c.id INNER JOIN
			ds_zone_data ds ON (c.id = ds.zone_id AND d.date = ds.date AND d.date_type = ds.date_type) INNER JOIN
			currency_rates cr ON (cr.from_currency_id = d.currency_id AND cr.to_currency_id = @currency_id)

	WHERE	ds.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id = 10) AND
			ds.metric_id = 3 AND
			ds.attribute_id = 0 AND
			(
				(@is_spot = 0 AND cr.date = d.date) OR
				(@is_spot = 1 AND cr.date = @date_spot)
			)

	GROUP BY ds.zone_id, d.metric_id, d.attribute_id, d.date, d.date_type, ds.val_i

	UPDATE #currencies SET processed = 1 WHERE id = @currency_id AND is_spot = @is_spot
END


-- Fetch existing ids so we can UPDATE against these rows (but only where calculated, not reported)
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type AND c.currency_id = ds.currency_id AND c.is_spot = ds.is_spot)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE @is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE @is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_d = c.value OR ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
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
	SELECT * FROM #calc WHERE zone_id = 3826 AND currency_id = 2 AND is_spot = 1 AND date >= '2012-01-01'
END


-- TODO: add benchmark by passing a start time to an audit function
SELECT 'Finished: aggregate_summed_currency_based_metric (1m 13s)'

DROP TABLE #currencies
DROP TABLE #calc
DROP TABLE #data

