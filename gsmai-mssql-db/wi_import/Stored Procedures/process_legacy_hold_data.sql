
CREATE PROCEDURE [dbo].[process_legacy_hold_data]

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- All data
	UPDATE	wi_import.dbo.ds_organisation_data
	SET		is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE	organisation_id IN (115,1981,2086,3135,3392,3944,4649,3414) AND approved = 1

	-- Operator-sourced connections, except M2M
	UPDATE	wi_import.dbo.ds_organisation_data
	SET 	is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE 	organisation_id IN (364,421) AND metric_id = 3 AND attribute_id <> 1251 AND source_id = 11 AND approved = 1

	-- M2M-impacted operator total/prepaid/contract connections
	UPDATE 	wi_import.dbo.ds_organisation_data
	SET 	is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE 	organisation_id IN (132,33,1197,408,676,167,119,706,175,473,189,47,222,828,832,393,176,488,634,561,140,402,465,521,295,317,404,362,105,467,532,212,778) AND metric_id = 3 AND attribute_id IN (0,99,822) AND approved = 1

	-- M2M-impacted operator total/prepaid connections
	UPDATE 	wi_import.dbo.ds_organisation_data
	SET 	is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE 	organisation_id IN (466,617) AND metric_id = 3 AND attribute_id IN (0,99) AND approved = 1

	-- M2M connections
	UPDATE 	wi_import.dbo.ds_organisation_data
	SET 	is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE 	organisation_id IN (638,636,431) AND metric_id IN (3,190) AND attribute_id = 1251 AND approved = 1
	
	-- Smartphone prepaid adoption
	UPDATE	wi_import.dbo.ds_organisation_data
	SET		is_held_for_review = 1, approval_hash = null, last_update_by = 11770, last_update_on = GETDATE()
	WHERE	organisation_id IN (107) AND metric_id IN (53) AND attribute_id = 1579 AND approved = 1
END