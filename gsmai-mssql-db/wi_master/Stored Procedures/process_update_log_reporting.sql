
CREATE PROCEDURE [dbo].[process_update_log_reporting]

AS

-- Create missing metric/attribute/date combinations
;WITH r AS
(
	SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY organisation_id, metric_id, attribute_id, date_type, date ORDER BY created_on DESC)
	FROM	wi_import.dbo.ds_organisation_data
	WHERE	approved = 1
)

INSERT	INTO log_reporting (metric_id, attribute_id, date, date_type)
SELECT	DISTINCT
		ds.metric_id,
		ds.attribute_id,
		ds.date,
		ds.date_type

FROM	wi_import.dbo.ds_organisation_data ds LEFT JOIN
		log_reporting l ON (ds.metric_id = l.metric_id AND ds.attribute_id = l.attribute_id AND ds.date = l.date AND ds.date_type = l.date_type)

WHERE	ds.id IN (SELECT id FROM r WHERE rank = 1) AND
		ds.date >= '2009-01-01' AND
		ds.date_type = 'Q' AND
		l.metric_id IS null


-- Update all entries with the latest count of organisations reporting that metric/attribute, and the corresponding (connections) market share
UPDATE log_reporting SET organisations_count = 0, organisations_market_share = 0

;WITH r AS
(
	SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY organisation_id, metric_id, attribute_id, date_type, date ORDER BY created_on DESC)
	FROM	wi_import.dbo.ds_organisation_data
)

UPDATE	l

SET		l.organisations_count = ds.count,
		l.organisations_market_share = CAST(ds.sum AS float)/CAST(ds2.val_i AS float)

FROM	log_reporting l INNER JOIN
		(
			SELECT	ds.metric_id, ds.attribute_id, ds.date, ds.date_type, COUNT(DISTINCT ds.organisation_id) count, SUM(ds2.val_i) sum
			FROM	wi_import.dbo.ds_organisation_data ds INNER JOIN wi_master.dbo.ds_organisation_data ds2 ON (ds.organisation_id = ds2.organisation_id AND ds2.metric_id = 3 AND ds2.attribute_id = 0 AND ds.date = ds2.date AND ds.date_type = ds2.date_type) INNER JOIN organisations o ON ds.organisation_id = o.id
			WHERE	ds.id IN (SELECT id FROM r WHERE rank = 1) AND o.type_id = 1089
			GROUP BY ds.metric_id, ds.attribute_id, ds.date, ds.date_type
		) ds ON (l.metric_id = ds.metric_id AND l.attribute_id = ds.attribute_id AND l.date = ds.date AND l.date_type = ds.date_type) INNER JOIN
		ds_zone_data ds2 ON (ds2.zone_id = 3826 AND ds2.metric_id = 3 AND ds2.attribute_id = 0 AND ds2.date = l.date AND ds2.date_type = l.date_type)
