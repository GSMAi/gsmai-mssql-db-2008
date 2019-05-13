
CREATE PROCEDURE [dbo].[process_recache_group_data]

(
	@date_start datetime,
	@date_end datetime
)

AS

DECLARE @current_quarter datetime, @ds_date_min datetime, @ds_date_max datetime, @last_update_on datetime

SET @current_quarter	= dbo.current_reporting_quarter()

SET @last_update_on		= GETDATE()
SET @ds_date_min		= '2000-01-01'
SET @ds_date_max		= '2021-01-01'

-- Group data
IF @date_start = @ds_date_min AND @date_end = @ds_date_max
BEGIN
	TRUNCATE TABLE dc_group_data
END
ELSE
BEGIN
	DELETE FROM dc_group_data WHERE date >= @date_start AND date < @date_end
END

INSERT INTO dc_group_data (id, organisation_id, ownership_threshold, metric_id, metric_order, attribute_id, attribute_order, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, definition_id, is_calculated, is_proportionate, is_spot, location, last_update_on, last_update_by)
SELECT	ds.id,
		ds.organisation_id,
		ds.ownership_threshold,
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
		ds.is_proportionate,
		ds.is_spot,
		CASE di.cleaned WHEN 2 THEN di.location_cleaned ELSE null END,
		@last_update_on,
		19880

FROM	ds_group_data ds INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id) LEFT JOIN
		definitions d ON (ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id) LEFT JOIN
		wi_import.dbo.ds_organisation_data di ON ds.import_id = di.id

WHERE	ds.status_id = 3 AND
		ds.privacy_id = 5 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		s.is_live_for_group_data = 1


-- Delete devices data prior to 2007
DELETE FROM dc_group_data WHERE metric_id IN (3,36,44,53,56,61,308) AND attribute_id IN (1432,1555,1556) AND date < '2007-01-01'


-- Group data sets
IF @date_start = @ds_date_min AND @date_end = @ds_date_max
BEGIN
	TRUNCATE TABLE dc_group_data_sets
	
	INSERT INTO dc_group_data_sets (organisation_id, metric_id, attribute_id)
	SELECT	DISTINCT organisation_id, metric_id, attribute_id
	FROM	dc_group_data
END
