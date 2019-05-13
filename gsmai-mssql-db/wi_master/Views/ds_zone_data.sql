CREATE VIEW [dbo].[ds_zone_data] WITH SCHEMABINDING AS select  
od.id as "id", 
od.fk_zone_id AS "zone_id",
od.fk_metric_id AS "metric_id",
att.id AS "attribute_id", 
od.fk_status_id AS "status_id",
od.fk_privacy_id AS "privacy_id",
od.[date] AS "date",
od.date_type AS "date_type",
od.val AS "val_d", 
od.val AS "val_i", 
cur.id AS "currency_id", 
s.id AS "source_id", 
conf.id AS "confidence_id", 
od.has_flags AS "has_flags",
od.is_calculated AS "is_calculated",
od.is_spot_price AS "is_spot",
NULL AS "import_id",
odv.created AS "created_on",
0 AS "created_by",
odv.created AS "last_update_on",
0 AS "last_updated_by",
odv.fk_data_view_id

from dbo.zone_data_view_link as odv
inner join dbo.zone_data as od ON od.id=odv.fk_zone_data_id
inner join dbo.zones as o ON o.id=od.fk_zone_id
inner join dbo.types as ot ON ot.id=o.fk_type_id
inner join dbo.metrics as m ON m.id=od.fk_metric_id
inner join dbo.attributes as att ON att.id=od.fk_attribute_id
inner join dbo.sources as s ON s.id=od.fk_source_id
inner join dbo.confidence as conf ON conf.id=od.fk_confidence_id
inner join dbo.currencies as cur ON cur.id=od.fk_currency_id
inner join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
inner join dbo.definitions as df ON (df.metric_id=od.fk_metric_id and df.attribute_id=od.fk_attribute_id)
--inner join dbo.zone_data_metadata as dm ON od.id = dm.fk_zone_data_id 

where odv.fk_data_view_id = 3
and odv.archive=0
and ds.id is not null
and o.id is not null
and od.archive=0