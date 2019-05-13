CREATE TYPE [dbo].[organisation_data_upsert_result_type] AS TABLE (
    [fk_organisation_data_id]      BIGINT   NULL,
    [fk_organisation_data_view_id] INT      NULL,
    [link_date]                    DATETIME NULL,
    [existing_id]                  BIGINT   NULL);

