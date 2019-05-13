
CREATE PROCEDURE [dbo].[data_operators_data]

(
	@organisation_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 0,
	@spot_historic bit = 0,
	@spot_quarter datetime = null
)

AS

IF @spot_quarter IS NULL
BEGIN
	SET @spot_quarter = dbo.current_reporting_quarter()
END


CREATE TABLE #data (id bigint, entity_id int, is_aggregate bit, metric_id int, metric_order int, attribute_id int, attribute_order int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, value decimal(22,4), currency_id int, currency_original_id int, source_id int, confidence_id int, definition_id int, has_flags bit, flags nvarchar(max) COLLATE DATABASE_DEFAULT, location nvarchar(max) COLLATE DATABASE_DEFAULT)

INSERT INTO #data
SELECT	dc.id,
		dc.organisation_id,
		0,
		dc.metric_id,
		dc.metric_order,
		dc.attribute_id,
		dc.attribute_order,
		dc.date datetime,
		dc.date_type,
		dc.val_d,
		dc.val_i,
		CASE WHEN dc.val_i IS NULL THEN dc.val_d * (CASE @currency_id WHEN 0 THEN 1 ELSE cr.value END) ELSE CAST(dc.val_i * (CASE @currency_id WHEN 0 THEN 1 ELSE cr.value END) AS decimal(22,4)) END value,
		CASE WHEN dc.currency_id = 0 THEN 0 WHEN @currency_id = 0 THEN dc.currency_id ELSE @currency_id END currency_id,
		dc.currency_id currency_original_id,
		dc.source_id,
		dc.confidence_id,
		dc.definition_id,
		dc.has_flags,
		dc.flags,
		dm.location
		
FROM	dc_organisation_data dc INNER JOIN
		currency_rates cr ON (cr.from_currency_id = dc.currency_id AND cr.to_currency_id = CASE @currency_id WHEN 0 THEN 1 ELSE @currency_id END) INNER JOIN
		data_sets s ON (dc.metric_id = s.metric_id AND dc.attribute_id = s.attribute_id)
	LEFT JOIN organisation_data_metadata as dm ON dc.id = dm.fk_organisation_data_id


WHERE	dc.organisation_id = @organisation_id AND
		dc.date >= @date_start AND
		dc.date < @date_end AND
		dc.date_type = @date_type AND
		s.attribute_id IS NOT null AND 
		s.show_in_metrics_only = 0 AND
		(
			(@spot_historic = 0 AND cr.date = dc.date) OR
			(@spot_historic = 1 AND cr.date = @spot_quarter)
		)
		
ORDER BY dc.metric_order, dc.attribute_order, dc.date


-- Data
SELECT * FROM #data

-- Metric, attribute combinations
SELECT	DISTINCT 
		metric_id, 
		metric_order, 
		attribute_id, 
		attribute_order
		
FROM	#data

GROUP BY metric_id, metric_order, attribute_id, attribute_order
ORDER BY metric_order, attribute_order

-- Date combinations
SELECT	DISTINCT 
		date, 
		date_type

FROM	#data

ORDER BY date


DROP TABLE #data
