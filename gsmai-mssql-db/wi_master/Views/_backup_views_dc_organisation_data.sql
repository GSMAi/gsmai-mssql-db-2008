CREATE VIEW [dbo].[_backup_views_dc_organisation_data] AS select 
od.id as "id", 
od.fk_organisation_id AS "organisation_id", 
m.id AS "metric_id", 
m.[order] AS "metric_order", 
att.id AS "attribute_id", 
att.[order] AS "attribute_order", 
od.[date],
od.date_type,
od.val AS "val_d", 
od.val AS "val_i", 
cur.id AS "currency_id", 
s.id AS "source_id", 
conf.id AS "confidence_id",
df.id AS "definition_id",
od.has_flags AS "has_flags",
NULL AS "flags",
dm.location AS "location",
odv.link_date AS "last_update_on",
0 AS "last_updated_by"

from dbo.organisation_data_view_link as odv
left join organisation_data as od ON od.id=odv.fk_organisation_data_id
left join dbo.organisations as o ON o.id=od.fk_organisation_id
left join dbo.metrics as m ON m.id=od.fk_metric_id
left join dbo.attributes as att ON att.id=od.fk_attribute_id
left join dbo.sources as s ON s.id=od.fk_source_id
left join dbo.confidence as conf ON conf.id=od.fk_confidence_id
left join dbo.currencies as cur ON cur.id=od.fk_currency_id
left join dbo.organisation_zone_link as ozl ON ozl.organisation_id=od.fk_organisation_id
left join dbo.zones as z ON z.id=ozl.zone_id
left join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
left join dbo.definitions as df ON (ds.fk_metric_id=df.metric_id and ds.fk_attribute_id=df.attribute_id)
left join dbo.organisation_data_metadata as dm ON od.id = dm.fk_organisation_data_id 

where odv.fk_data_view_id = 4
and ds.id is not null
and o.id is not null
and not (ds.id IN (490, 497, 511, 514, 561, 562, 563, 564, 565, 566, 600, 512, 515, 513, 516) and od.[date]<'2007-01-01')
and not (ds.id IN (3, 609, 610, 611, 612, 500, 615, 618, 619, 628, 631, 634) and od.[date]<'2010-01-01')
and not (ds.id IN (65, 202) and s.id IN (3, 22))
and not (ds.id IN (88, 61, 84, 97, 65, 707) and od.[date]>GETDATE())