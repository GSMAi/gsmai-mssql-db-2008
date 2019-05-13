
CREATE PROCEDURE [dbo].[process_merge_import_zone_data]

(
	@approval_hash nvarchar(64),
	@debug bit = 1
)

AS

-- Get the import data that corresponds to @approval_hash
CREATE TABLE #import (zone_id int, metric_id int, attribute_id int, date datetime, date_type char(1) COLLATE DATABASE_DEFAULT, val_d decimal(22,4), val_i bigint, currency_id int, source_id int, confidence_id int, id bigint, import_id bigint, processed bit)

INSERT INTO #import
SELECT	zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, null, id, 0
FROM 	wi_import.dbo.ds_zone_data
WHERE 	approved = 1 AND is_held_for_review = 0 AND approval_hash = @approval_hash

-- Get any existing ids for the corresponding data (TODO: currency_id, is_calculated?)
UPDATE	i
SET		i.id = ds.id
FROM	ds_zone_data ds INNER JOIN #import i ON (ds.zone_id = i.zone_id AND ds.metric_id = i.metric_id and ds.attribute_id = i.attribute_id AND ds.date = i.date AND ds.date_type = i.date_type)

IF @debug = 0
BEGIN
	-- Now merge the import with the data set, replacing those with existing ids
	UPDATE	ds
	SET		ds.val_d = i.val_d, ds.val_i = i.val_i, ds.currency_id = i.currency_id, ds.source_id = i.source_id, ds.confidence_id = i.confidence_id, ds.is_calculated = 0, ds.is_spot = 0, ds.import_id = i.import_id, ds.last_update_on = GETDATE(), ds.last_update_by = 11770
	FROM	ds_zone_data ds INNER JOIN #import i ON ds.id = i.id
	WHERE	i.id IS NOT null

	UPDATE #import SET processed = 1 WHERE id IS NOT null


	-- Now create any new data that doesn't have an existing id
	INSERT INTO ds_zone_data (zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, is_calculated, is_spot, import_id, created_by)
	SELECT	DISTINCT zone_id, metric_id, attribute_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, 0, 0, import_id, 11770
	FROM	#import
	WHERE	id IS null
END

IF @debug = 1
BEGIN
	SELECT * FROM #import
END

DROP TABLE #import
