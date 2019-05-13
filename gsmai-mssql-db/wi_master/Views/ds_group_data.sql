CREATE VIEW [dbo].[ds_group_data] AS select 
od.id as "id", 
od.fk_organisation_id AS "organisation_id", 
od.ownership as "ownership_threshold",
m.id AS "metric_id", 
att.id AS "attribute_id",
od.fk_status_id AS "status_id", 
od.fk_privacy_id AS "privacy_id", 
od.[date],
od.date_type,
NULL as "val_d",
od.val_sum AS "val_i", 
cur.id AS "currency_id", 
s.id AS "source_id", 
conf.id AS "confidence_id",
od.has_flags AS "has_flags",
od.is_calculated AS "is_calculated",
0 as "is_proportionate",
NULL as "is_spot",
NULL as "import_id",
odv.link_date AS "created_on",
0 AS "created_by",
odv.link_date AS "last_update_on",
0 AS "last_update_by"

from dbo.group_data_view_link as odv
left join group_data as od ON od.id=odv.fk_group_data_id
left join dbo.organisations as o ON o.id=od.fk_organisation_id
left join dbo.metrics as m ON m.id=od.fk_metric_id
left join dbo.attributes as att ON att.id=od.fk_attribute_id
left join dbo.sources as s ON s.id=od.fk_source_id
left join dbo.confidence as conf ON conf.id=od.fk_confidence_id
left join dbo.currencies as cur ON cur.id=od.fk_currency_id
left join dbo.organisation_zone_link as ozl ON ozl.organisation_id=od.fk_organisation_id
left join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
left join dbo.definitions as df ON (ds.fk_metric_id=df.metric_id and ds.fk_attribute_id=df.attribute_id)
left join dbo.organisation_data_metadata as dm ON od.id = dm.fk_organisation_data_id 

where odv.fk_data_view_id = 3
and odv.archive = 0
and ds.id is not null
and o.id is not null

union ALL

select 
distinct od.id as "id", 
od.fk_organisation_id AS "organisation_id", 
od.ownership as "ownership_threshold",
m.id AS "metric_id", 
att.id AS "attribute_id",
od.fk_status_id AS "status_id", 
od.fk_privacy_id AS "privacy_id", 
od.[date],
od.date_type,
NULL as "val_d",
od.val_proportionate AS "val_i", 
cur.id AS "currency_id", 
s.id AS "source_id", 
conf.id AS "confidence_id",
od.has_flags AS "has_flags",
od.is_calculated AS "is_calculated",
1 as "is_proportionate",
NULL as "is_spot",
NULL as "import_id",
odv.link_date AS "created_on",
0 AS "created_by",
odv.link_date AS "last_update_on",
0 AS "last_update_by"

from dbo.group_data_view_link as odv
left join group_data as od ON od.id=odv.fk_group_data_id
left join dbo.organisations as o ON o.id=od.fk_organisation_id
left join dbo.metrics as m ON m.id=od.fk_metric_id
left join dbo.attributes as att ON att.id=od.fk_attribute_id
left join dbo.sources as s ON s.id=od.fk_source_id
left join dbo.confidence as conf ON conf.id=od.fk_confidence_id
left join dbo.currencies as cur ON cur.id=od.fk_currency_id
left join dbo.organisation_zone_link as ozl ON ozl.organisation_id=od.fk_organisation_id
left join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
left join dbo.definitions as df ON (ds.fk_metric_id=df.metric_id and ds.fk_attribute_id=df.attribute_id)
left join dbo.organisation_data_metadata as dm ON od.id = dm.fk_organisation_data_id 

where odv.fk_data_view_id = 3
and odv.archive = 0
and ds.id is not null
and o.id is not null