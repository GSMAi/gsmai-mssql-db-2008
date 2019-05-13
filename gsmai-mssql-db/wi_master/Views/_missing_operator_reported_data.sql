CREATE VIEW [dbo].[_missing_operator_reported_data] AS --missing operator reported data from [wi_master.dbo.ds_organisation_data]
select od.id from wi_import.dbo.ds_organisation_data as od
left join wi_master.dbo.latest_ranked_reported_data as rankedLookup ON rankedLookup.id=od.id
left join wi_master.dbo.ds_organisation_data as d ON 
(d.organisation_id=od.organisation_id 
and d.metric_id=od.metric_id 
and d.attribute_id=od.attribute_id
and d.[date]=od.[date]
and d.date_type=od.date_type)
left join wi_master.dbo.data_sets as ds ON (ds.metric_id=od.metric_id and ds.attribute_id=od.attribute_id)
where rankedLookup.rank=1
and d.id IS NULL
and ds.is_live=1
and od.last_update_on<=DATEADD(day, -1, GETDATE())