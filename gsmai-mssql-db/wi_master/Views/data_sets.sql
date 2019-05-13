CREATE VIEW [dbo].[data_sets] AS /*select ISNULL(dsm.id, ds.id) as id 
	,ISNULL(dsm.[fk_metric_id], ds.metric_id) as metric_id
      ,ISNULL(dsm.[fk_attribute_id], ds.attribute_id) as attribute_id
      ,ds.[type_id]
      ,ISNULL(ds.[default_date_type], 'Q') as default_date_type
      ,ISNULL(dsm.[show_on_website], ds.is_live) as is_live
      ,ds.[is_live_for_organisation_data]
      ,ds.[is_live_for_group_data]
      ,ds.[is_live_for_country_data]
      ,ds.[is_live_for_region_data]
      ,ds.[is_aggregated]
      ,ds.[is_aggregated_from_organisation_data]
      ,ds.[is_aggregated_from_zone_data]
      ,ISNULL(dswl.has_forecasts, ds.has_forecasts) as has_forecasts
      ,ISNULL(dswl.has_organisation_data, ds.has_organisation_data) as has_organisation_data
      ,ISNULL(dswl.has_group_data, ds.has_group_data) as has_group_data
      ,ISNULL(dswl.has_zone_data, ds.has_country_data) as has_country_data
      ,ISNULL(dswl.has_regional_data, ds.has_region_data) as has_region_data
      ,ISNULL(dswl.has_organisation_rank, ds.has_organisation_rank) as has_organisation_rank
      ,ISNULL(dswl.has_group_rank, ds.has_group_rank) as has_group_rank
      ,ISNULL(dswl.has_country_rank, ds.has_country_rank) as has_country_rank
      ,ISNULL(dswl.has_region_rank, ds.has_region_rank) as has_region_rank
      ,ISNULL(ds.show_in_metrics_only, 0) as [show_in_metrics_only]
      ,ds.[created_on]
      ,ds.[created_by]
      ,ds.[super_set_base]
      ,ds.[web_set_base]
      ,ds.[super_set_base_zones] 
from data_sets_master as dsm
full join _data_sets as ds ON ds.metric_id=dsm.fk_metric_id and ds.attribute_id=dsm.fk_attribute_id
left join data_sets_master_website_link as dswl ON dswl.fk_data_sets_master_id=dsm.id*/
select ISNULL(dsm.id, ds.id) as id 
	,ISNULL(dsm.[fk_metric_id], ds.metric_id) as metric_id
      ,ISNULL(dsm.[fk_attribute_id], ds.attribute_id) as attribute_id
      ,ds.[type_id]
      ,ISNULL(ds.[default_date_type], 'Q') as default_date_type
      ,ISNULL(dsm.[show_on_website], ds.is_live) as is_live
      ,ISNULL(ds.[is_live_for_organisation_data], 0) as is_live_for_organisation_data
      ,ISNULL(ds.[is_live_for_group_data], 0) as is_live_for_group_data
      ,ISNULL(ds.[is_live_for_country_data], 0) as is_live_for_country_data
      ,ISNULL(ds.[is_live_for_region_data], 0) as is_live_for_region_data
      ,ISNULL(ds.[is_aggregated], 0) as is_aggregated
      ,ISNULL(ds.[is_aggregated_from_organisation_data], 0) as is_aggregated_from_organisation_data
      ,ISNULL(ds.[is_aggregated_from_zone_data], 0) as is_aggregated_from_zone_data
      ,ISNULL(dswl.has_forecasts, ds.has_forecasts) as has_forecasts
      ,ISNULL(dswl.has_organisation_data, ds.has_organisation_data) as has_organisation_data
      ,ISNULL(dswl.has_group_data, ds.has_group_data) as has_group_data
      ,ISNULL(dswl.has_zone_data, ds.has_country_data) as has_country_data
      ,ISNULL(dswl.has_regional_data, ds.has_region_data) as has_region_data
      ,ISNULL(dswl.has_organisation_rank, ds.has_organisation_rank) as has_organisation_rank
      ,ISNULL(dswl.has_group_rank, ds.has_group_rank) as has_group_rank
      ,ISNULL(dswl.has_country_rank, ds.has_country_rank) as has_country_rank
      ,ISNULL(dswl.has_region_rank, ds.has_region_rank) as has_region_rank
      ,ISNULL(ds.show_in_metrics_only, 0) as [show_in_metrics_only]
      ,ds.[created_on]
      ,ds.[created_by]
      ,ds.[super_set_base]
      ,ds.[web_set_base]
      ,ds.[super_set_base_zones] 
from data_sets_master as dsm
full join _data_sets as ds ON ds.metric_id=dsm.fk_metric_id and ds.attribute_id=dsm.fk_attribute_id
left join data_sets_master_website_link as dswl ON dswl.fk_data_sets_master_id=dsm.id
