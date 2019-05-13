CREATE VIEW [dbo].[view_zone_data_reported] AS select distinct od.id as org_data_id, od.fk_zone_id AS "zone_id", o.name as "zone_name", ot.id AS "zone_type_id", ot.term AS "zone_type", m.term AS "metric", 
att.term AS "attribute", od.date, od.date_type,
od.has_flags, od.val AS "value", s.term AS "source", conf.term AS "confidence", cur.iso_code AS "currency_iso_code", 
odv.fk_data_view_id AS "view_id", od.is_spot_price AS "is_spot_price"
from dbo.zone_data_view_link as odv
left join zone_data as od ON od.id=odv.fk_zone_data_id
left join dbo.zones as o ON o.id=od.fk_zone_id
left join dbo.types as ot ON ot.id=o.fk_type_id
left join dbo.metrics as m ON m.id=od.fk_metric_id
left join dbo.attributes as att ON att.id=od.fk_attribute_id
left join dbo.sources as s ON s.id=od.fk_source_id
left join dbo.confidence as conf ON conf.id=od.fk_confidence_id
left join dbo.currencies as cur ON cur.id=od.fk_currency_id
left join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
where odv.fk_data_view_id IN (1, 2)
and odv.archive=0
and ds.has_zone_data=1
and ds.id is not null
and o.id is not null