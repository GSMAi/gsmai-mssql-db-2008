CREATE VIEW [dbo].[_missing_zone_forecast_data] AS select od.id from wi_import.dbo.ds_zone_forecast_data as od
left join dbo.latest_ranked_zone_forecasted_data as rankedLookup ON rankedLookup.id=od.id
left join dbo.ds_zone_data as d ON 
(d.zone_id=od.zone_id 
and d.metric_id=od.metric_id 
and d.attribute_id=od.attribute_id
and d.[date]=od.[date]
and d.date_type=od.date_type)
left join wi_master.dbo.data_sets as ds ON (ds.metric_id=od.metric_id and ds.attribute_id=od.attribute_id)
where rankedLookup.rank=1
and d.id IS NULL
and ds.is_live=1