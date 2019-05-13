
CREATE PROCEDURE [dbo].[process_create_revision]

(
	@debug bit = 1
)

AS

DECLARE @revision datetime, @revision_id int

SET @revision 		= GETDATE()
SET @revision_id	= (SELECT MAX(revision_id) FROM wi_revisions.dbo.ds_organisation_data) + 1


-- Keep a distributed sample of the revisions
CREATE TABLE #revisions (revision datetime)

INSERT INTO #revisions
SELECT DISTINCT revision FROM wi_revisions.dbo.ds_organisation_data

-- Keep daily revisions for a month
DELETE FROM #revisions WHERE revision > DATEADD(day, -31, @revision)

-- Keep weekly revisions for a year
DELETE FROM #revisions WHERE revision > DATEADD(year, -1, @revision) AND DATEPART(weekday, revision) = 2 -- Monday 01:00 revision (ie Sunday calculations)

-- Keep monthly revisions indefinitely, delete previously weekly revisions that aren't the first revision in the month
DELETE FROM #revisions WHERE revision < DATEADD(year, -1, @revision) AND revision IN
(
	SELECT	revision
	FROM	(
				SELECT	revision, RANK() OVER (PARTITION BY DATEPART(year, revision), DATEPART(month, revision) ORDER BY revision) rank
				FROM	#revisions
			) ranks
	WHERE	rank = 1
)

IF @debug = 1
BEGIN
	SELECT 'Revisions to delete:'
	SELECT * FROM #revisions ORDER BY revision
END

IF @debug = 0
BEGIN
	DELETE FROM wi_revisions.dbo.ds_organisation_data WHERE revision IN (SELECT revision FROM #revisions)
	DELETE FROM wi_revisions.dbo.ds_zone_data WHERE revision IN (SELECT revision FROM #revisions)
END

DROP TABLE #revisions


-- Create revision
IF @debug = 0
BEGIN
	-- Operator data
	INSERT INTO wi_revisions.dbo.ds_organisation_data (revision_id, revision, organisation_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, created_on, created_by, last_update_on, last_update_by)
	SELECT	@revision_id,
			@revision,
			ds.organisation_id,
			ds.metric_id,
			ds.attribute_id,
			ds.status_id,
			ds.privacy_id,
			ds.date,
			ds.date_type,
			ds.val_d,
			ds.val_i,
			ds.currency_id,
			ds.source_id,
			ds.confidence_id,
			ds.has_flags,
			ds.is_calculated,
			ds.created_on,
			CASE WHEN ds.created_by IS NULL THEN 0 ELSE ds.created_by END,
			ds.last_update_on,
			CASE WHEN ds.last_update_by IS NULL THEN 0 ELSE ds.last_update_by END
			
	FROM	wi_master.dbo.ds_organisation_data ds
			
	WHERE	ds.metric_id IN (3,10,18)				-- Revisions of all connections, ARPU and revenue splits


	-- Region/country data
	INSERT INTO wi_revisions.dbo.ds_zone_data (revision_id, revision, zone_id, metric_id, attribute_id, status_id, privacy_id, date, date_type, val_d, val_i, currency_id, source_id, confidence_id, has_flags, is_calculated, is_spot, created_on, created_by, last_update_on, last_update_by)
	SELECT	@revision_id,
			@revision,
			ds.zone_id,
			ds.metric_id,
			ds.attribute_id,
			ds.status_id,
			ds.privacy_id,
			ds.date,
			ds.date_type,
			ds.val_d,
			ds.val_i,
			ds.currency_id,
			ds.source_id,
			ds.confidence_id,
			0,
			ds.is_calculated,
			ds.is_spot,
			ds.created_on,
			CASE WHEN ds.created_by IS NULL THEN 0 ELSE ds.created_by END,
			ds.last_update_on,
			CASE WHEN ds.last_update_by IS NULL THEN 0 ELSE ds.last_update_by END
			
	FROM	wi_master.dbo.ds_zone_data ds
			
	WHERE	ds.metric_id IN (1,3,10,18,44,181,182)	-- Revisions of subscribers, connections, ARPU, revenue, connections penetration, subscriber penetration and SIMs/subscriber
END
