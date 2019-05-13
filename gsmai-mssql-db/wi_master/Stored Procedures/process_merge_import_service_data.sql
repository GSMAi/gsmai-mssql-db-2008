
CREATE PROCEDURE [dbo].[process_merge_import_service_data]

(
	@approval_hash nvarchar(64),
	@debug bit = 1
)

AS

-- Get the import data that corresponds to @approval_hash
CREATE TABLE #import (service_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, currency_id int, source_id int, confidence_id int, id bigint, import_id bigint, processed bit)

INSERT INTO #import
SELECT	service_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, null, id, 0
FROM 	wi_import.dbo.ds_service_data
WHERE 	approved = 1 AND approval_hash = @approval_hash

-- Get any existing ids for the corresponding data
UPDATE	i
SET		i.id = ds.id
FROM	ds_service_data ds INNER JOIN #import i ON (ds.service_id = i.service_id AND ds.metric_id = i.metric_id and ds.attribute_id = i.attribute_id AND ds.date = i.date AND ds.date_type = i.date_type)

IF @debug = 0
BEGIN
	-- Now merge the import with the data set, replacing those with existing ids
	UPDATE	ds
	SET		ds.val_d = i.val_d, ds.val_i = i.val_i, ds.currency_id = i.currency_id, ds.source_id = i.source_id, ds.confidence_id = i.confidence_id, ds.import_id = i.import_id, ds.last_update_on = GETDATE(), ds.last_update_by = 11770
	FROM	ds_service_data ds INNER JOIN #import i ON ds.id = i.id
	WHERE	i.id IS NOT null

	UPDATE #import SET processed = 1 WHERE id IS NOT null


	-- Now create any new data that doesn't have an existing id
	INSERT INTO ds_service_data (service_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, import_id, created_by)
	SELECT	DISTINCT service_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, import_id, 11770
	FROM	#import
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	SELECT * FROM #import
END

DROP TABLE #import
