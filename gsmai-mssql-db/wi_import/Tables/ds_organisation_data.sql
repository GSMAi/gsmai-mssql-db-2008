CREATE TABLE [dbo].[ds_organisation_data] (
    [id]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [organisation_id]    INT             NOT NULL,
    [metric_id]          INT             NOT NULL,
    [attribute_id]       INT             NOT NULL,
    [date]               DATETIME        NOT NULL,
    [date_type]          CHAR (1)        NOT NULL,
    [val_d]              DECIMAL (22, 4) NULL,
    [val_i]              BIGINT          NULL,
    [currency_id]        INT             NOT NULL,
    [source_id]          INT             NOT NULL,
    [confidence_id]      INT             NOT NULL,
    [privacy_id]         INT             NULL,
    [has_flags]          BIT             CONSTRAINT [DF_ds_organisation_data_has_flags] DEFAULT ((0)) NOT NULL,
    [location]           NVARCHAR (MAX)  NULL,
    [location_cleaned]   NVARCHAR (MAX)  NULL,
    [definition]         NVARCHAR (MAX)  NULL,
    [notes]              NVARCHAR (MAX)  NULL,
    [approved]           TINYINT         CONSTRAINT [DF_ds_organisation_data_approved] DEFAULT (NULL) NULL,
    [approval_hash]      NVARCHAR (64)   NULL,
    [import_hash]        NVARCHAR (64)   NULL,
    [stasis]             BIT             CONSTRAINT [DF_ds_organisation_data_stasis] DEFAULT ((0)) NOT NULL,
    [processed]          BIT             NULL,
    [cleaned]            TINYINT         CONSTRAINT [DF_ds_organisation_data_path_cleaned] DEFAULT ((0)) NOT NULL,
    [is_latest]          BIT             CONSTRAINT [DF_ds_organisation_data_is_deleted] DEFAULT ((0)) NOT NULL,
    [is_held_for_review] BIT             CONSTRAINT [DF_ds_organisation_data_is_held_for_review] DEFAULT ((0)) NOT NULL,
    [hash]               BINARY (16)     NULL,
    [index_hash]         BINARY (16)     NULL,
    [created_on]         DATETIME        CONSTRAINT [DF_ds_organisation_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]         INT             CONSTRAINT [DF_ds_organisation_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]     DATETIME        CONSTRAINT [DF_ds_organisation_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]     INT             CONSTRAINT [DF_ds_organisation_data_last_update_by] DEFAULT ((0)) NOT NULL,
    [archive]            BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ds_organisation_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data]
    ON [dbo].[ds_organisation_data]([organisation_id] ASC, [metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data_approval]
    ON [dbo].[ds_organisation_data]([approved] ASC)
    INCLUDE([id], [organisation_id], [metric_id], [attribute_id], [date], [date_type], [val_d], [val_i], [index_hash], [created_on]);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data_hash]
    ON [dbo].[ds_organisation_data]([hash] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ds_organisation_data_index_hash]
    ON [dbo].[ds_organisation_data]([index_hash] ASC);


GO
CREATE NONCLUSTERED INDEX [PT_ds_organisation_data_created_update_on]
    ON [dbo].[ds_organisation_data]([created_on] ASC, [last_update_on] ASC);

