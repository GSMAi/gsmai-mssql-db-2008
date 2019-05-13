
CREATE PROCEDURE [dbo].[aggregate_subscribers]

(
	@date_start datetime,
	@date_end datetime,
	@debug bit = 1
)

AS

CREATE TABLE #data (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,4), subregion_id int, region_id int, geoscheme_id int)
CREATE TABLE #calc (id bigint, zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, value decimal(22,4), processed bit)

-- Collect all existing country subscriber and active connections figures
INSERT INTO #data
SELECT	DISTINCT
		ds.id,
		ds.zone_id,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		ds.val_i,
		zl.zone_id subregion_id,
		zl2.zone_id region_id,
		zl3.zone_id geoscheme_id
		
FROM	ds_zone_data ds INNER JOIN
		zones z ON ds.zone_id = z.id INNER JOIN
		zone_link zl ON z.id = zl.subzone_id INNER JOIN
		zone_link zl2 ON zl.zone_id = zl2.subzone_id INNER JOIN
		zone_link zl3 ON zl2.zone_id = zl3.subzone_id INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id)

WHERE	zl3.zone_id IN (SELECT DISTINCT id FROM zones WHERE type_id IN (43,44)) AND		-- This query will include duplicate countries for multiple geoscheme joins
		ds.metric_id IN (1,3,322) AND													-- Make sure only unique sums are generated where the data isn't grouped by subregion_id or region_id
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		s.attribute_id IS NOT null AND													-- Valid attributes (but only those aggregated from country data)
		s.is_aggregated = 1 AND 
		s.is_aggregated_from_zone_data = 1 AND
		z.type_id = 10
		
ORDER BY ds.zone_id, ds.date, ds.date_type


-- Calculate aggregates
INSERT INTO #calc
SELECT	null, 3826, metric_id, attribute_id, date, date_type, SUM(value), 0
FROM	#data
WHERE	geoscheme_id = 3936																-- To avoid double-counting, use each country's primary geoscheme only
GROUP BY metric_id, attribute_id, date, date_type
ORDER BY metric_id, attribute_id, date, date_type

INSERT INTO #calc
SELECT	null, region_id, metric_id, attribute_id, date, date_type, SUM(value), 0
FROM	#data
WHERE	geoscheme_id = 3936																-- No point aggregating placeholder "regions" that exist to satisfy zone_link joins
GROUP BY region_id, metric_id, attribute_id, date, date_type
ORDER BY region_id, metric_id, attribute_id, date, date_type

INSERT INTO #calc
SELECT	null, subregion_id, metric_id, attribute_id, date, date_type, SUM(value), 0
FROM	#data
WHERE	geoscheme_id <> 3954 OR (geoscheme_id = 3954 AND subregion_id IN (3956,3957,3958))
GROUP BY subregion_id, metric_id, attribute_id, date, date_type
ORDER BY subregion_id, metric_id, attribute_id, date, date_type


-- Get any existing ids which we can UPDATE on
UPDATE	c
SET		c.id = ds.id
FROM	#calc c INNER JOIN ds_zone_data ds ON (c.zone_id = ds.zone_id AND c.metric_id = ds.metric_id AND c.attribute_id = ds.attribute_id AND c.date = ds.date AND c.date_type = ds.date_type)

-- Remove any NULL data
DELETE FROM #calc WHERE value IS null


IF @debug = 0
BEGIN
	-- UPDATE the values that already exist
	UPDATE	ds
	SET		ds.val_d = null, ds.val_i = ROUND(c.value, 0), ds.source_id = 6, ds.confidence_id = 194, ds.is_calculated = 1, ds.last_update_on = CASE WHEN ds.val_i = c.value THEN ds.last_update_on ELSE GETDATE() END, ds.last_update_by = CASE WHEN ds.val_i = c.value THEN ds.last_update_by ELSE 11770 END
	FROM	ds_zone_data ds INNER JOIN #calc c ON ds.id = c.id
	WHERE	c.processed = 0

	-- INSERT the remainder
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, created_by)
	SELECT	zone_id, metric_id, attribute_id, date, date_type, null, ROUND(value, 0), 0, 6, 194, 1, 11770
	FROM	#calc
	WHERE	id IS null AND processed = 0
END

IF @debug = 1
BEGIN
	SELECT * FROM #calc ORDER BY zone_id, attribute_id, date, date_type
END


SELECT 'Finished: aggregate_subscribers (7s)'

DROP TABLE #data
DROP TABLE #calc
