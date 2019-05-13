
CREATE PROCEDURE [dbo].[process_recache_zone_data]

(
	@date_start datetime,
	@date_end datetime
)

AS

DECLARE @current_quarter datetime, @ds_date_min datetime, @ds_date_max datetime, @last_update_on datetime

SET @current_quarter	= dbo.current_reporting_quarter()

SET @last_update_on		= GETDATE()
SET @ds_date_min		= '1950-01-01'
SET @ds_date_max		= '2026-01-01'

-- Region, country data
IF @date_start = @ds_date_min AND @date_end = @ds_date_max
BEGIN
	SELECT 'Running: process_recache_zone_data (using truncate)'
	
	TRUNCATE TABLE dc_zone_data
END
ELSE
BEGIN
	SELECT 'Running: process_recache_zone_data (using delete)'
	
	DELETE FROM dc_zone_data WHERE date >= @date_start AND date < @date_end
END

INSERT INTO dc_zone_data (id, zone_id, metric_id, metric_order, attribute_id, attribute_order, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, definition_id, is_calculated, is_spot, location, last_update_on, last_update_by)
SELECT	ds.id,
		ds.zone_id,
		m.id,
		m.[order],
		a.id,
		a.[order],
		ds.date,
		ds.date_type,
		ds.val_d,
		ds.val_i,
		ds.currency_id,
		ds.source_id,
		ds.confidence_id,
		d.id,
		ds.is_calculated,
		ds.is_spot,
		CASE di.cleaned WHEN 2 THEN di.location_cleaned ELSE null END,
		@last_update_on,
		19880

FROM	ds_zone_data ds INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id) LEFT JOIN
		definitions d ON (ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id) LEFT JOIN
		wi_import.dbo.ds_zone_data di ON ds.import_id = di.id

WHERE	ds.status_id = 3 AND
		ds.privacy_id = 5 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		s.is_live_for_country_data = 1


-- Delete non-draft-subscriber data after 2020
DELETE FROM dc_zone_data WHERE metric_id NOT IN (322) AND date >= '2021-01-01'

-- Delete M2M prior to 2010
DELETE FROM dc_zone_data WHERE metric_id IN (3,36,44,53,56,61) AND attribute_id = 1251 AND date < '2010-01-01'
DELETE FROM dc_zone_data WHERE metric_id IN (190,309,310,311,312) AND date < '2010-01-01'

-- Delete mobile internet data prior to 2010
DELETE FROM dc_zone_data WHERE metric_id IN (1,178,179,180,181,305,322,323,324,325,326,328) AND attribute_id IN (1581,1582,1583) AND date < '2010-01-01'

-- Delete devices data prior to 2007
DELETE FROM dc_zone_data WHERE metric_id IN (3,36,44,53,56,61,308) AND attribute_id IN (1432,1555,1556) AND date < '2007-01-01'


-- Zone data sets
IF @date_start = @ds_date_min AND @date_end = @ds_date_max
BEGIN
	TRUNCATE TABLE dc_zone_data_sets
	
	INSERT INTO dc_zone_data_sets (zone_id, metric_id, attribute_id)
	SELECT	DISTINCT zone_id, metric_id, attribute_id
	FROM	dc_zone_data
END
