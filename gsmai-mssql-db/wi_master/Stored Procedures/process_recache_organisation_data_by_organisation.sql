
CREATE PROCEDURE [dbo].[process_recache_organisation_data_by_organisation]

(
	@organisation_id int,
	@date_start datetime,
	@date_end datetime
)

AS

DECLARE @current_quarter datetime, @last_update_on datetime

SET @current_quarter	= dbo.current_reporting_quarter()
SET @last_update_on		= GETDATE()

-- Organisation data
SELECT 'Running: process_recache_organisation_data (using delete for a single organisation id)'
DELETE FROM dc_organisation_data WHERE organisation_id = @organisation_id AND date >= @date_start AND date < @date_end

INSERT INTO dc_organisation_data (id, organisation_id, metric_id, metric_order, attribute_id, attribute_order, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, definition_id, location, last_update_on, last_update_by)
SELECT	ds.id,
		ds.organisation_id,
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
		di.location_cleaned,
		@last_update_on,
		19880

FROM	ds_organisation_data ds INNER JOIN
		metrics m ON ds.metric_id = m.id INNER JOIN
		attributes a ON ds.attribute_id = a.id INNER JOIN
		data_sets s ON (ds.metric_id = s.metric_id AND ds.attribute_id = s.attribute_id) LEFT JOIN
		definitions d ON (ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id) LEFT JOIN
		wi_import.dbo.ds_organisation_data di ON ds.import_id = di.id

WHERE	ds.organisation_id = @organisation_id AND
		ds.status_id = 3 AND
		ds.privacy_id = 5 AND
		ds.date >= @date_start AND
		ds.date < @date_end AND
		ds.date_type IN ('Q','H','Y') AND
		s.is_live_for_organisation_data = 1

-- Flags
;WITH f AS
(
	SELECT	fdl.ds_id,
			(
				SELECT	CAST(f.id AS varchar) + ',' AS [text()]
				FROM	flags f INNER JOIN flag_ds_link fdl2 ON f.id = fdl2.flag_id
				WHERE	f.publish = 1 AND fdl.ds = fdl2.ds AND fdl.ds_id = fdl2.ds_id	-- Only "live" flags
				ORDER BY f.id
				FOR XML PATH ('')
			) flags
	FROM	flag_ds_link fdl
	WHERE	fdl.ds = 'organisation_data'
)

UPDATE	dc
SET		dc.has_flags = 1, dc.flags = LEFT(f.flags, LEN(f.flags)-1)
FROM	dc_organisation_data dc INNER JOIN f ON dc.id = f.ds_id
WHERE	dc.organisation_id = @organisation_id AND f.flags IS NOT null


-- Delete M2M prior to 2010
DELETE FROM dc_organisation_data WHERE organisation_id = @organisation_id AND metric_id IN (3,36,44,53,56,61) AND attribute_id = 1251 AND date < '2010-01-01'
DELETE FROM dc_organisation_data WHERE organisation_id = @organisation_id AND metric_id IN (190,309,310,311,312) AND date < '2010-01-01'

-- Delete devices data prior to 2007
DELETE FROM dc_organisation_data WHERE organisation_id = @organisation_id AND metric_id IN (3,36,44,53,56,61,308) AND attribute_id IN (1432,1555,1556) AND date < '2007-01-01'


-- Organisation data sets
DELETE FROM dc_organisation_data_sets WHERE organisation_id = @organisation_id
	
INSERT INTO dc_organisation_data_sets (organisation_id, metric_id, attribute_id)
SELECT	DISTINCT organisation_id, metric_id, attribute_id
FROM	dc_organisation_data
WHERE	organisation_id = @organisation_id
