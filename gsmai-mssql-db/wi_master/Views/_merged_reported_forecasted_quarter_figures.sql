CREATE VIEW [dbo].[_merged_reported_forecasted_quarter_figures] AS select ofd.organisation_id, o.name AS "organisation_name", o.type_id AS "organisation_type_id", m.term AS "metric", 
att.term AS "attribute", ofd.[date], ofd.date_type, 0 AS "has_flags", 
CASE WHEN ofd.val_d IS NULL THEN ofd.val_i ELSE ofd.val_d END AS "value",
s.term AS "source", cf.term "confidence", cur.iso_code AS "currency_iso_code", z.id AS "zone_id", z.name AS "zone_name", 
z.type_id AS "zone_type_id"
	FROM wi_import.gsmai.forecast_data as fd
	LEFT JOIN wi_import.dbo.ds_organisation_forecast_data as ofd ON ofd.id=fd.id
	LEFT JOIN wi_master.dbo.organisations as o ON o.id=ofd.organisation_id
	LEFT JOIN wi_master.dbo.organisation_zone_link AS ozl ON ozl.organisation_id=o.id
	LEFT JOIN wi_master.dbo.zones as z ON z.id=ozl.zone_id
	LEFT JOIN wi_master.dbo.metrics as m ON m.id=ofd.metric_id
	LEFT JOIN wi_master.dbo.attributes as att ON att.id=ofd.attribute_id
	LEFT JOIN wi_master.dbo.sources as s ON s.id=ofd.source_id
	LEFT JOIN wi_master.dbo.confidence as cf ON cf.id=ofd.confidence_id
	LEFT JOIN wi_master.dbo.currencies as cur ON cur.id=ofd.currency_id
	
UNION ALL

select od.organisation_id, o.name AS "organisation_name", o.type_id AS "organisation_type_id", m.term AS "metric", 
att.term AS "attribute", od.[date], od.date_type, od.has_flags, 
CASE WHEN od.val_d IS NULL THEN od.val_i ELSE od.val_d END AS "value",
s.term AS "source", cf.term "confidence", cur.iso_code AS "currency_iso_code", z.id AS "zone_id", z.name AS "zone_name", 
z.type_id AS "zone_type_id"
	FROM wi_import.gsmai.reported_data as rd
	LEFT JOIN wi_import.dbo.ds_organisation_data as od ON od.id=rd.id
	LEFT JOIN wi_master.dbo.organisations as o ON o.id=od.organisation_id
	LEFT JOIN wi_master.dbo.organisation_zone_link AS ozl ON ozl.organisation_id=o.id
	LEFT JOIN wi_master.dbo.zones as z ON z.id=ozl.zone_id
	LEFT JOIN wi_master.dbo.metrics as m ON m.id=od.metric_id
	LEFT JOIN wi_master.dbo.attributes as att ON att.id=od.attribute_id
	LEFT JOIN wi_master.dbo.sources as s ON s.id=od.source_id
	LEFT JOIN wi_master.dbo.confidence as cf ON cf.id=od.confidence_id
	LEFT JOIN wi_master.dbo.currencies as cur ON cur.id=od.currency_id