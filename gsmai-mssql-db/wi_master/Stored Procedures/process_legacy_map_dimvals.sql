CREATE PROCEDURE [dbo].[process_legacy_map_dimvals] 

(
	@debug bit = 1
)

AS

DECLARE @metric_id int, @attribute_id int

IF @debug = 0
BEGIN
	-- Fix for incorrect read-in files (incorrect wholesale dimension for connections)
	UPDATE wi_import.dbo.ds_organisation_forecast_data SET dimension_id = 1 WHERE metric_id IN (3,53) AND dimension_id = 7 AND dimension_val_id IN (987,1055)

	-- Remove ignored data and any lingering legacy technology-net-off data
	DELETE FROM wi_import.dbo.ds_organisation_forecast_data WHERE source_id = 24
	DELETE FROM wi_import.dbo.ds_organisation_forecast_data WHERE attribute_id IN (1398,1400,1402,1404,1406,1408,1410,1412,1414)

	-- Cross update dimensions with attributes in old-format import data tables
	UPDATE	ds
	SET		ds.attribute_id = d.attribute_id
	FROM	wi_import.dbo.ds_organisation_forecast_data ds INNER JOIN
			wi_master.dbo.attribute_dimval_legacy_link d ON (ds.dimension_id = d.dimension_id AND ds.dimension_val_id = d.dimval_id)
	WHERE	ds.attribute_id IS null AND ds.approved = 1

	-- Automatically create new dimvalue entries for new metrics since this schema is being depreciated
	CREATE TABLE #dimvals (metric_id int, attribute_id int, processed bit)

	INSERT INTO #dimvals
	SELECT	DISTINCT ds.metric_id, ds.attribute_id, 0
	FROM	wi_import.dbo.ds_organisation_data ds LEFT JOIN
			wi_master.dbo.attribute_dimval_legacy_link d ON (ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id)
	WHERE	d.dimval_id IS null AND ds.attribute_id IS NOT null

	UNION

	SELECT	DISTINCT ds.metric_id, ds.attribute_id, 0
	FROM	wi_import.dbo.ds_organisation_forecast_data ds LEFT JOIN
			wi_master.dbo.attribute_dimval_legacy_link d ON (ds.metric_id = d.metric_id AND ds.attribute_id = d.attribute_id)
	WHERE	d.dimval_id IS null AND ds.attribute_id IS NOT null

	WHILE EXISTS (SELECT TOP 1 * FROM #dimvals WHERE processed = 0)
	BEGIN
		SET @metric_id		= (SELECT TOP 1 metric_id FROM #dimvals WHERE processed = 0)
		SET @attribute_id	= (SELECT TOP 1 attribute_id FROM #dimvals WHERE metric_id = @metric_id AND processed = 0)

		INSERT INTO wi_master.dbo.attribute_dimval_legacy_link (dimension_id, metric_id, attribute_id) VALUES (0, @metric_id, @attribute_id)
	
		UPDATE #dimvals SET processed = 1 WHERE metric_id = @metric_id AND attribute_id = @attribute_id
	END

	DROP TABLE #dimvals
END
