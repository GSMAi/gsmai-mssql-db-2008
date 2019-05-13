CREATE VIEW [dbo].[_merged_zone_reported_forecasted_quarter_figures] AS select z.id AS "zone_id", z.name AS "zone_name", z.type_id AS "zone_type_id", m.term AS "metric", 
att.term AS "attribute", zfd.[date], zfd.date_type, 0 AS "has_flags", 
CASE WHEN zfd.val_d IS NULL THEN zfd.val_i ELSE zfd.val_d END AS "value",
s.term AS "source", cf.term "confidence", cur.iso_code AS "currency_iso_code", p.term AS "privacy", 0 AS "is_spot"
	FROM wi_import.gsmai.zone_forecast_data as fd
	LEFT JOIN wi_import.dbo.ds_zone_forecast_data as zfd ON zfd.id=fd.id
	LEFT JOIN wi_master.dbo.zones as z ON z.id=zfd.zone_id
	LEFT JOIN wi_master.dbo.metrics as m ON m.id=zfd.metric_id
	LEFT JOIN wi_master.dbo.attributes as att ON att.id=zfd.attribute_id
	LEFT JOIN wi_master.dbo.sources as s ON s.id=zfd.source_id
	LEFT JOIN wi_master.dbo.confidence as cf ON cf.id=zfd.confidence_id
	LEFT JOIN wi_master.dbo.currencies as cur ON cur.id=zfd.currency_id
	LEFT JOIN wi_master.dbo.privacy as p ON p.id=zfd.privacy_id
	
UNION ALL

select z.id AS "zone_id", z.name AS "zone_name", z.type_id AS "zone_type_id", m.term AS "metric", 
att.term AS "attribute", zfd.[date], zfd.date_type, 0 AS "has_flags", 
CASE WHEN zfd.val_d IS NULL THEN zfd.val_i ELSE zfd.val_d END AS "value",
s.term AS "source", cf.term "confidence", cur.iso_code AS "currency_iso_code", p.term AS "privacy", 0 AS "is_spot"
	FROM wi_import.gsmai.zone_reported_data as fd
	LEFT JOIN wi_import.dbo.ds_zone_data as zfd ON zfd.id=fd.id
	LEFT JOIN wi_master.dbo.zones as z ON z.id=zfd.zone_id
	LEFT JOIN wi_master.dbo.metrics as m ON m.id=zfd.metric_id
	LEFT JOIN wi_master.dbo.attributes as att ON att.id=zfd.attribute_id
	LEFT JOIN wi_master.dbo.sources as s ON s.id=zfd.source_id
	LEFT JOIN wi_master.dbo.confidence as cf ON cf.id=zfd.confidence_id
	LEFT JOIN wi_master.dbo.currencies as cur ON cur.id=zfd.currency_id
	LEFT JOIN wi_master.dbo.privacy as p ON p.id=zfd.privacy_id