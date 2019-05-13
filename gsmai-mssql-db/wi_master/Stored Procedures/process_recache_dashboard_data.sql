
CREATE PROCEDURE [dbo].[process_recache_dashboard_data]

AS

DECLARE @last_update_on datetime 
SET @last_update_on = GETDATE()

TRUNCATE TABLE dc_dashboard_zone_data

-- Current data
INSERT INTO dc_dashboard_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, last_update_on, last_update_by)
SELECT zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, @last_update_on, 19880 FROM
(
	SELECT	ds.zone_id,
			ds.metric_id,
			ds.attribute_id,
			ds.date,
			ds.date_type,
			ds.val_d,
			ds.val_i,
			ds.currency_id,
			ds.source_id,
			ds.confidence_id,
			RANK() OVER (PARTITION BY ds.zone_id, ds.metric_id, ds.attribute_id ORDER BY ds.date DESC) rank
			
	FROM	ds_zone_data ds

	WHERE	(
				(
					(
						(ds.metric_id IN (1,3,43,44) AND ds.attribute_id = 0) OR 
						(ds.metric_id = 53 AND ds.attribute_id IN (99,755,799,1292))
					) AND ds.date_type = 'Q'
				) OR
				(
					ds.metric_id = 171 AND
					ds.attribute_id = 1501 AND
					ds.date_type = 'Y'
				)
			) AND
			ds.currency_id IN (0,2) AND
			--ds.date <= dbo.current_reporting_quarter()
			ds.date <= '2015-10-01'
) ds WHERE rank = 1

-- Year-ago data
INSERT INTO dc_dashboard_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, last_update_on, last_update_by)
SELECT	ds.zone_id,
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type,
		ds.val_d,
		ds.val_i,
		ds.currency_id,
		ds.source_id,
		ds.confidence_id,
		@last_update_on,
		19880
		
FROM	ds_zone_data ds INNER JOIN
		dc_dashboard_zone_data dc ON (ds.zone_id = dc.zone_id AND ds.metric_id = dc.metric_id AND ds.attribute_id = dc.attribute_id AND ds.date = DATEADD(year, -1, dc.date) AND ds.date_type = dc.date_type AND ds.currency_id = dc.currency_id)
		
