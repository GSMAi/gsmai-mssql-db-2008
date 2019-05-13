CREATE PROCEDURE [dbo].[merge_zone_reported_forecasted_figures]
AS

CREATE TABLE #reported_data (id int)
CREATE TABLE #forecast_data (id int)

BEGIN TRY
	insert into #reported_data
	SELECT
		  CASE WHEN A.id IS null THEN B.id ELSE A.id END AS "id"

	FROM (
		  --Query returns latest ranked reported figures
		  SELECT od.id, od.zone_id, od.metric_id, od.attribute_id, od.[date], od.date_type, od.val_d, 
				od.val_i, od.currency_id, od.source_id, od.confidence_id, od.privacy_id, 0 AS "has_flags"
		  FROM wi_master.dbo.latest_ranked_zone_quarterly_data AS lrrd
		  LEFT JOIN wi_import.dbo.ds_zone_data AS od ON od.id=lrrd.id
		  WHERE lrrd.rank=1
		  AND od.date_type='Q'
	) AS A
	FULL OUTER JOIN (
		  --FULL OUTER JOIN on the right forecasted figures. Query returns latest ranked forecasted figures
		  SELECT od.id, od.zone_id, od.metric_id, od.attribute_id, od.[date], od.date_type, od.val_d, 
				od.val_i, od.currency_id, od.source_id, od.confidence_id, od.privacy_id, 0 AS "has_flags"
		  FROM wi_master.dbo.latest_ranked_zone_forecasted_quarterly_data AS lrfd
		  LEFT JOIN wi_import.dbo.ds_zone_forecast_data AS od ON lrfd.id=od.id
		  WHERE lrfd.rank=1
		  AND od.date_type='Q'
	) AS B ON (
		  A.zone_id=B.zone_id
		  AND A.metric_id=B.metric_id
		  AND A.attribute_id=B.attribute_id
		  AND A.[date]=B.[date]
		  AND A.date_type=B.date_type
	)
	WHERE A.id IS NOT NULL
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'insert into #reported_data'
END CATCH  


BEGIN TRY
	insert into #forecast_data
	SELECT
		  CASE WHEN A.id IS null THEN B.id ELSE A.id END AS "id"

	FROM (
		  --Query returns latest ranked reported figures
		  SELECT od.id, od.zone_id, od.metric_id, od.attribute_id, od.[date], od.date_type, od.val_d, 
				od.val_i, od.currency_id, od.source_id, od.confidence_id, od.privacy_id, 0 AS "has_flags"
		  FROM wi_master.dbo.latest_ranked_zone_quarterly_data AS lrrd
		  LEFT JOIN wi_import.dbo.ds_zone_data AS od ON od.id=lrrd.id
		  WHERE lrrd.rank=1
		  AND od.date_type='Q'
	) AS A
	FULL OUTER JOIN (
		  --FULL OUTER JOIN on the right forecasted figures. Query returns latest ranked forecasted figures
		  SELECT od.id, od.zone_id, od.metric_id, od.attribute_id, od.[date], od.date_type, od.val_d, 
				od.val_i, od.currency_id, od.source_id, od.confidence_id, od.privacy_id, 0 AS "has_flags"
		  FROM wi_master.dbo.latest_ranked_zone_forecasted_quarterly_data AS lrfd
		  LEFT JOIN wi_import.dbo.ds_zone_forecast_data AS od ON lrfd.id=od.id
		  WHERE lrfd.rank=1
		  AND od.date_type='Q'
	) AS B ON (
		  A.zone_id=B.zone_id
		  AND A.metric_id=B.metric_id
		  AND A.attribute_id=B.attribute_id
		  AND A.[date]=B.[date]
		  AND A.date_type=B.date_type
	)
	WHERE A.id IS NULL
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'insert into #forecast_data'
END CATCH  



BEGIN TRY
	TRUNCATE TABLE wi_import.gsmai.zone_reported_data
	
	INSERT INTO wi_import.gsmai.zone_reported_data
	SELECT id FROM #reported_data
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'INSERT INTO wi_import.gsmai.zone_reported_data'
END CATCH  

BEGIN TRY
	TRUNCATE TABLE wi_import.gsmai.zone_forecast_data
	
	INSERT INTO wi_import.gsmai.zone_forecast_data
	SELECT id FROM #forecast_data
END TRY  
BEGIN CATCH  
	execute [dbo].[collect_errors] @query_string = 'INSERT INTO wi_import.gsmai.zone_forecast_data'
END CATCH  


DROP TABLE #reported_data
DROP TABLE #forecast_data