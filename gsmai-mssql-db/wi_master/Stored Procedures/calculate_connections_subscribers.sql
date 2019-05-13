
CREATE PROCEDURE [dbo].[calculate_connections_subscribers]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

CREATE TABLE #data (id bigint, entity_id int, country_id int, is_aggregate bit, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6), source_id int, confidence_id int)
CREATE TABLE #calc (id bigint, entity_id int, country_id int, is_aggregate bit, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,6), source_id int, confidence_id int, is_decimal bit, processed bit)		-- Calculate to a greater accuracy than we store, to inform last digit rounding

-- Fetch organisation- and zone-level data
INSERT INTO #data
SELECT	ds.id,
		ds.organisation_id,
		oz.zone_id,
		0,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		ds.val_i,
		ds.source_id,
		ds.confidence_id

FROM	ds_organisation_data ds INNER JOIN
		organisation_zone_link oz ON ds.organisation_id = oz.organisation_id INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id)

WHERE	ds.metric_id IN (3,190) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		s.attribute_id IS NOT null AND 
		s.is_aggregated = 1 AND
		s.is_aggregated_from_organisation_data = 1

ORDER BY ds.organisation_id, ds.date, ds.date_type

INSERT INTO #data
SELECT	ds.id,
		ds.zone_id,
		null,
		1,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		ds.val_i,
		ds.source_id,
		ds.confidence_id

FROM	ds_zone_data ds INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id)

WHERE	(
			(ds.metric_id IN (1,3,190,322) AND s.attribute_id IS NOT null AND s.is_aggregated = 1) OR	-- Connections (including/excluding M2M), subscribers
			(ds.metric_id = 43 AND ds.attribute_id = 0)													-- Population
		) AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y')

ORDER BY ds.zone_id, ds.metric_id, ds.attribute_id


-- Calculate derivatives (metric_id 36,41,42,44,53,56,61 for connections, 309,310,311,312 for M2M-inclusive connections and 178,179,180,181,182,305 for subscribers (323,324,325,326,327,328 for DRAFT subscribers))

-- Net additions (36, 178/323, 309)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d2.metric_id WHEN 1 THEN 178 WHEN 3 THEN 36 WHEN 190 THEN 309 WHEN 322 THEN 323 ELSE null END, d2.attribute_id, d2.date, d2.date_type, d2.value-d1.value, d2.source_id, d2.confidence_id, 0, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.entity_id AND d1.is_aggregate = d2.is_aggregate AND d1.metric_id = d2.metric_id AND d1.attribute_id = d2.attribute_id AND d2.date = DATEADD(month, CASE d1.date_type WHEN 'Q' THEN 3 WHEN 'H' THEN 6 WHEN 'Y' THEN 12 END, d1.date) AND d1.date_type = d2.date_type)
WHERE	d1.metric_id IN (1,3,190,322) AND d2.metric_id IN (1,3,190,322) AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null

-- Market share (41)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, 0, 41, d2.attribute_id, d2.date, d2.date_type, d2.value/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.country_id AND d1.metric_id = d2.metric_id AND d1.attribute_id = d2.attribute_id AND d1.date = d2.date AND d1.date_type = d2.date_type)
WHERE	d1.metric_id = 3 AND d2.metric_id = 3 AND d1.is_aggregate = 1 AND d2.is_aggregate = 0 AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null

-- Market share, net additions (42)
INSERT INTO #calc
SELECT	null, c2.entity_id, c2.country_id, 0, 42, c2.attribute_id, c2.date, c2.date_type, c2.value/c1.value, c2.source_id, c2.confidence_id, 1, 0
FROM	#calc c1 INNER JOIN #calc c2 ON (c1.entity_id = c2.country_id AND c1.metric_id = c2.metric_id AND c1.attribute_id = c2.attribute_id AND c1.date = c2.date AND c1.date_type = c2.date_type)
WHERE	c1.metric_id = 36 AND c2.metric_id = 36 AND c1.is_aggregate = 1 AND c2.is_aggregate = 0 AND c1.value <> 0 AND c1.value IS NOT NULL AND c2.value <> 0 AND c2.value IS NOT null

-- Market penetration (44, 181/326)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d2.metric_id WHEN 1 THEN 181 WHEN 3 THEN 44 WHEN 322 THEN 326 ELSE null END, d2.attribute_id, d2.date, d2.date_type, d2.value/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (((d2.is_aggregate = 0 AND d1.entity_id = d2.country_id) OR (d2.is_aggregate = 1 AND d1.entity_id = d2.entity_id)) AND d1.date = d2.date AND d1.date_type = d2.date_type)
WHERE	d1.metric_id = 43 AND d1.attribute_id = 0 AND d2.metric_id IN (1,3,322) AND d1.is_aggregate = 1 AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null

-- % share (53, 305/328, 312)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d1.metric_id WHEN 1 THEN 305 WHEN 3 THEN 53 WHEN 190 THEN 312 WHEN 322 THEN 328 ELSE null END, d2.attribute_id, d2.date, d2.date_type, d2.value/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.entity_id AND d1.is_aggregate = d2.is_aggregate AND d1.metric_id = d2.metric_id AND d1.date = d2.date AND d1.date_type = d2.date_type)
WHERE	d1.metric_id IN (1,3,190,322) AND d2.metric_id IN (1,3,190,322) AND d1.attribute_id = 0 AND d2.attribute_id <> 0 AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null

DELETE FROM #calc WHERE metric_id = 53 AND attribute_id = 1251											-- Only show M2M as a share of M2M-inclusive connections
DELETE FROM #calc WHERE metric_id = 53 AND attribute_id IN (1432,1579,1580) AND confidence_id = 192		-- Don't adjust reported smartphone (total, prepaid, contract) share of connections

-- Growth, sequential (56, 179/324, 310)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d2.metric_id WHEN 1 THEN 179 WHEN 3 THEN 56 WHEN 190 THEN 310 WHEN 322 THEN 324 ELSE null END, d2.attribute_id, d2.date, d2.date_type, (d2.value-d1.value)/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.entity_id AND d1.is_aggregate = d2.is_aggregate AND d1.metric_id = d2.metric_id AND d1.attribute_id = d2.attribute_id AND d2.date = DATEADD(month, CASE d1.date_type WHEN 'Q' THEN 3 WHEN 'H' THEN 6 WHEN 'Y' THEN 12 END, d1.date) AND d1.date_type = d2.date_type)
WHERE	d1.metric_id IN (1,3,190,322) AND d2.metric_id IN (1,3,190,322) AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null

-- Growth, annual (61, 180/325, 311)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d2.metric_id WHEN 1 THEN 180 WHEN 3 THEN 61 WHEN 190 THEN 311 WHEN 322 THEN 325 ELSE null END, d2.attribute_id, d2.date, d2.date_type, (d2.value-d1.value)/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.entity_id AND d1.is_aggregate = d2.is_aggregate AND d1.metric_id = d2.metric_id AND d1.attribute_id = d2.attribute_id AND d2.date = DATEADD(month, 12, d1.date) AND d1.date_type = d2.date_type)
WHERE	d1.metric_id IN (1,3,190,322) AND d2.metric_id IN (1,3,190,322) AND d1.date_type = 'Q' AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null  -- No point having sequential and annual growth for half-year/annual data!

-- SIMs per subscriber (182/327)
INSERT INTO #calc
SELECT	null, d2.entity_id, d2.country_id, d2.is_aggregate, CASE d1.metric_id WHEN 1 THEN 182 WHEN 322 THEN 327 ELSE null END, 0, d2.date, d2.date_type, d2.value/d1.value, d2.source_id, d2.confidence_id, 1, 0
FROM	#data d1 INNER JOIN #data d2 ON (d1.entity_id = d2.entity_id AND d1.is_aggregate = d2.is_aggregate AND d1.date = d2.date AND d1.date_type = d2.date_type)
WHERE	d1.metric_id IN (1,322) AND d1.attribute_id = 0 AND d2.metric_id = 3 AND d2.attribute_id = 204 AND d1.is_aggregate = 1 AND d2.is_aggregate = 1 AND d1.value <> 0 AND d1.value IS NOT NULL AND d2.value <> 0 AND d2.value IS NOT null


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_organisation_data ds ON (c.entity_id = ds.organisation_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)
WHERE	c.is_aggregate = 0

UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.entity_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)
WHERE	c.is_aggregate = 1

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = CASE c.is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE c.is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_by ELSE 11770 END
	FROM	ds_organisation_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	c.is_aggregate = 0 AND c.processed = 0

	UPDATE	ds
	SET		ds.val_d = CASE c.is_decimal WHEN 1 THEN ROUND(c.value, 4) ELSE null END, ds.val_i = CASE c.is_decimal WHEN 1 THEN null ELSE ROUND(c.value, 0) END, ds.last_update_on = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN (c.is_decimal = 1 AND ds.val_d = ROUND(c.value, 4)) OR (c.is_decimal = 0 AND ds.val_i = ROUND(c.value, 0)) THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	c.is_aggregate = 1 AND c.processed = 0

	-- INSERT the remainder
	INSERT INTO ds_organisation_data (organisation_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	entity_id, metric_id, attribute_id, date, date_type, CASE is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, 0, 6, 194, 1, 11770
	FROM	#calc
	WHERE	id IS null AND is_aggregate = 0 AND processed = 0

	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	entity_id, metric_id, attribute_id, date, date_type, CASE is_decimal WHEN 1 THEN ROUND(value, 4) ELSE null END, CASE is_decimal WHEN 1 THEN null ELSE ROUND(value, 0) END, 0, 6, 194, 1, 11770
	FROM	#calc
	WHERE	id IS null AND is_aggregate = 1 AND processed = 0


	-- Freeze the mobile internet as a % of unique subscriber values until workbook cut-over
	-- TODO: remove on workbook cut-over
	UPDATE wi_import.dbo.ds_zone_forecast_data SET approved = 1, approval_hash = import_hash WHERE import_hash = 'will-2015-05-28-14-22-59'
	EXEC process_merge_import_zone_forecast_data 'will-2015-05-28-14-22-59', 0
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc WHERE metric_id IN (182,327) ORDER BY is_aggregate, entity_id, metric_id, attribute_id, date, date_type
END


SELECT 'Finished: calculate_connections_subscribers (22s)'

DROP TABLE #data
DROP TABLE #calc
