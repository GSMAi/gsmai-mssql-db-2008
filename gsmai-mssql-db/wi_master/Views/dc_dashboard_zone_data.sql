CREATE VIEW [dbo].[dc_dashboard_zone_data] AS
select zd.id,
	zd.fk_zone_id as zone_id,
	zd.fk_metric_id as metric_id,
	zd.fk_attribute_id as attribute_id,
	zd.date,
	zd.date_type,
	(CASE WHEN m.unit_id = 37 THEN zd.val ELSE NULL END) as val_d,
	(CASE WHEN m.unit_id != 37 THEN zd.val ELSE NULL END) as val_i,
	zd.fk_currency_id as currency_id,
	zd.fk_source_id as source_id,
	zd.fk_confidence_id as confidence_id,
	GETDATE() as last_updated_on,
	0 as last_updated_by
from wi_master.dbo.zone_data_view_link as zvl
left join wi_master.dbo.zone_data as zd on zd.id = zvl.fk_zone_data_id
left join wi_master.dbo.zones as z on z.id = zd.fk_zone_id
left join metrics as m ON m.id=zd.fk_metric_id
where zvl.fk_data_view_id = 3
and z.type_id = 10
and (
	zd.date_type = 'Q'
	and DAY(date) = 1
	and MONTH(date) = 10
	and year(zd.date) in (
		YEAR(DATEADD(Year,-1,GETDATE())),
		YEAR(DATEADD(Year,-2,GETDATE()))
	)
	and (
		(zd.fk_metric_id in (1, 3, 43, 44, 171) and zd.fk_attribute_id in (0, 1501))
			or 
		(zd.fk_metric_id = 53 and zd.fk_attribute_id in (99, 755, 799, 1292))
	)
)