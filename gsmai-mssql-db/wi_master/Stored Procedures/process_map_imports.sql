CREATE PROCEDURE [dbo].[process_map_imports] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Add new data points to cleaning
	INSERT INTO wi_import.dbo.cleaning (ds, ds_id)
	SELECT	'organisation_data', ds.id
	FROM	wi_import.dbo.ds_organisation_data ds LEFT JOIN wi_import.dbo.cleaning c ON (c.ds = 'organisation_data' AND c.ds_id = ds.id)
	WHERE	c.ds_id IS null AND ds.approved = 1

	-- Mark the data set where flags have been parsed
	UPDATE wi_import.dbo.ds_organisation_data SET has_flags = 0

	UPDATE	ds
	SET		ds.has_flags = 1
	FROM	wi_import.dbo.ds_organisation_data ds INNER JOIN
			wi_import.dbo.flag_ds_link fdl ON (fdl.ds = 'organisation_data' AND fdl.ds_id = ds.id)
		
	-- Now cross-update the master data set to match import ids and flags
	UPDATE wi_master.dbo.ds_organisation_data SET import_merge_hash = null WHERE import_merge_hash = ''
	UPDATE wi_master.dbo.ds_organisation_data SET import_id = null

	;WITH di AS
	(
		SELECT	*, rank = ROW_NUMBER() OVER (PARTITION BY index_hash ORDER BY created_on DESC)
		FROM	wi_import.dbo.ds_organisation_data
		WHERE	approved = 1
	)

	UPDATE	ds
	SET		ds.import_id = di.id, ds.has_flags = di.has_flags
	FROM	wi_master.dbo.ds_organisation_data ds INNER JOIN
			di ON (di.rank = 1 AND ds.organisation_id = di.organisation_id AND ds.metric_id = di.metric_id AND ds.attribute_id = di.attribute_id AND ds.date = di.date AND ds.date_type = di.date_type AND (ds.val_i = di.val_i OR ds.val_d = di.val_d))
	WHERE	ds.import_id IS null

	-- Populate the master flag link where a referenced import has flags
	TRUNCATE TABLE wi_master.dbo.flag_ds_link

	INSERT INTO wi_master.dbo.flag_ds_link (ds, ds_id, flag_id)
	SELECT	'organisation_data', ds.id, fdl.flag_id
	FROM	wi_master.dbo.ds_organisation_data ds INNER JOIN
			wi_import.dbo.ds_organisation_data di ON ds.import_id = di.id INNER JOIN
			wi_import.dbo.flag_ds_link fdl ON (fdl.ds = 'organisation_data' AND fdl.ds_id = di.id)
	WHERE	ds.has_flags = 1
END
