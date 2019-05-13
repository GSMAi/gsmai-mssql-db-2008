CREATE PROCEDURE [dbo].[process_delete_duplicates] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Add new data point and metadata hashes
	EXEC wi_import.dbo.process_create_hashes @debug
	
	
	-- Delete duplicates from data stores where only partial import sets should exist
	/*;WITH r AS
	(
		SELECT	id, index_hash, hash, created_on, rank = ROW_NUMBER() OVER (PARTITION BY index_hash ORDER BY created_on DESC)
		FROM	wi_import.dbo.ds_organisation_data
		WHERE	index_hash IS NOT null
	),
	r2 AS
	(
		SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY hash ORDER BY created_on)	-- ASC, to keep the original import
		FROM	r
		WHERE	rank IN (1,2)															-- Only the most recent import and its prior comparison
	)
	DELETE FROM wi_import.dbo.ds_organisation_data WHERE id IN (SELECT id FROM r2 WHERE rank <> 1)*/
	
	
	/*;WITH r AS
	(
		SELECT	id, index_hash, hash, created_on, rank = ROW_NUMBER() OVER (PARTITION BY index_hash ORDER BY created_on DESC)
		FROM	wi_import.dbo.ds_zone_data
		WHERE	index_hash IS NOT null
	),
	r2 AS
	(
		SELECT	id, rank = ROW_NUMBER() OVER (PARTITION BY hash ORDER BY created_on)	-- ASC, to keep the original import
		FROM	r
		WHERE	rank IN (1,2)															-- Only the most recent import and its prior comparison
	)
	DELETE FROM wi_import.dbo.ds_zone_data WHERE id IN (SELECT id FROM r2 WHERE rank <> 1)*/


	-- And auto-approve data that remains unchanged in all except its text metadata (source file, definition or notes) 
	;WITH r AS
	(
		SELECT	id, index_hash, hash, created_on, rank = ROW_NUMBER() OVER (PARTITION BY index_hash ORDER BY created_on DESC)
		FROM	wi_import.dbo.ds_organisation_data
		WHERE	index_hash IN (SELECT DISTINCT index_hash FROM wi_import.dbo.ds_organisation_data WHERE approved IS null)
	)

	UPDATE	ds

	SET		ds.approved = 1, ds.approval_hash = ds.import_hash, last_update_by = 11770

	FROM	(SELECT * FROM wi_import.dbo.ds_organisation_data WHERE id IN (SELECT id FROM r WHERE rank = 1)) ds INNER JOIN 
			(SELECT * FROM wi_import.dbo.ds_organisation_data WHERE id IN (SELECT id FROM r WHERE rank = 2)) ds2 ON ds.index_hash = ds2.index_hash

	WHERE	ds2.approved = 1 AND
			ds.currency_id = ds2.currency_id AND
			ds.source_id = ds2.source_id AND
			ds.confidence_id = ds2.confidence_id AND
			(
				(ds.val_i IS null AND ds.val_d = ds2.val_d) OR
				(ds.val_d IS null AND ds.val_i = ds2.val_i)
			)

	/*;WITH r AS
	(
		SELECT	id, index_hash, hash, created_on, rank = ROW_NUMBER() OVER (PARTITION BY index_hash ORDER BY created_on DESC)
		FROM	wi_import.dbo.ds_zone_data
		WHERE	index_hash IN (SELECT DISTINCT index_hash FROM wi_import.dbo.ds_zone_data WHERE approved IS null)
	)

	UPDATE	ds

	SET		ds.approved = 1, ds.approval_hash = ds.import_hash, last_update_by = 11770

	FROM	(SELECT * FROM wi_import.dbo.ds_zone_data WHERE id IN (SELECT id FROM r WHERE rank = 1)) ds INNER JOIN 
			(SELECT * FROM wi_import.dbo.ds_zone_data WHERE id IN (SELECT id FROM r WHERE rank = 2)) ds2 ON ds.index_hash = ds2.index_hash

	WHERE	ds2.approved = 1 AND
			ds.currency_id = ds2.currency_id AND
			ds.source_id = ds2.source_id AND
			ds.confidence_id = ds2.confidence_id AND
			(
				(ds.val_i IS null AND ds.val_d = ds2.val_d) OR
				(ds.val_d IS null AND ds.val_i = ds2.val_i)
			)*/
END


