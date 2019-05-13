﻿CREATE TABLE [dbo].[organisation_data_all] (
    [id]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [organisation_id]   INT             NOT NULL,
    [metric_id]         INT             NOT NULL,
    [attribute_id]      INT             NOT NULL,
    [status_id]         INT             NOT NULL,
    [privacy_id]        INT             NOT NULL,
    [date]              DATETIME        NOT NULL,
    [date_type]         CHAR (1)        NOT NULL,
    [val_d]             DECIMAL (22, 4) NULL,
    [val_i]             BIGINT          NULL,
    [currency_id]       INT             NOT NULL,
    [source_id]         INT             NOT NULL,
    [confidence_id]     INT             NOT NULL,
    [has_flags]         BIT             NOT NULL,
    [is_calculated]     BIT             NOT NULL,
    [import_id]         BIGINT          NULL,
    [import_merge_hash] NVARCHAR (64)   NULL,
    [created_on]        DATETIME        NOT NULL,
    [created_by]        INT             NOT NULL,
    [last_update_on]    DATETIME        NOT NULL,
    [last_update_by]    INT             NOT NULL
);

