CREATE VIEW [dbo].[dc_zone_data] WITH SCHEMABINDING AS select  
od.id as "id", 
od.fk_zone_id AS "zone_id",
od.fk_metric_id AS "metric_id",
m.[order] AS "metric_order",
att.id AS "attribute_id", 
att.[order] AS "attribute_order", 
od.[date] AS "date",
od.date_type AS "date_type",
od.val AS "val_d", 
od.val AS "val_i", 
od.fk_currency_id AS "currency_id", 
od.fk_source_id AS "source_id", 
od.fk_confidence_id AS "confidence_id", 
df.id AS "definition_id",
od.has_flags AS "has_flags",
od.is_calculated AS "is_calculated",
od.is_spot_price AS "is_spot",
NULL AS "flags",
NULL AS "location",
odv.created AS "last_update_on",
0 AS "last_updated_by",
odv.fk_data_view_id

from dbo.zone_data_view_link as odv
inner join dbo.zone_data as od ON od.id=odv.fk_zone_data_id
inner join dbo.metrics as m ON m.id=od.fk_metric_id
inner join dbo.attributes as att ON att.id=od.fk_attribute_id
inner join dbo.data_sets_master as ds ON (ds.fk_metric_id=od.fk_metric_id and ds.fk_attribute_id=od.fk_attribute_id)
inner join dbo.definitions as df ON (df.metric_id=od.fk_metric_id and df.attribute_id=od.fk_attribute_id)
--inner join dbo.zone_data_metadata as dm ON od.id = dm.fk_zone_data_id 

where odv.fk_data_view_id = 3
and odv.archive=0
and ds.show_on_website=1
and ds.id is not null
and od.archive=0
GO
CREATE UNIQUE CLUSTERED INDEX [dc_zone_data_unique]
    ON [dbo].[dc_zone_data]([fk_data_view_id] ASC, [id] ASC);


GO
CREATE NONCLUSTERED INDEX [dc_zone_data_comb]
    ON [dbo].[dc_zone_data]([attribute_id] ASC, [confidence_id] ASC, [currency_id] ASC, [date] ASC, [date_type] ASC, [definition_id] ASC, [has_flags] ASC, [is_calculated] ASC, [is_spot] ASC, [metric_id] ASC, [source_id] ASC, [zone_id] ASC);

