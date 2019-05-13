CREATE TABLE [dbo].[ds_zone_data] (
    [id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [zone_id]            INT            NOT NULL,
    [metric_id]          INT            NOT NULL,
    [attribute_id]       INT            NOT NULL,
    [date]               DATETIME       NOT NULL,
    [date_type]          CHAR (1)       NOT NULL,
    [val_d]              FLOAT (53)     NULL,
    [val_i]              BIGINT         NULL,
    [currency_id]        INT            NOT NULL,
    [source_id]          INT            NOT NULL,
    [confidence_id]      INT            NOT NULL,
    [privacy_id]         INT            NULL,
    [location]           NVARCHAR (MAX) NULL,
    [location_cleaned]   NVARCHAR (MAX) NULL,
    [definition]         NVARCHAR (MAX) NULL,
    [notes]              NVARCHAR (MAX) NULL,
    [approved]           TINYINT        NULL,
    [approval_hash]      NVARCHAR (64)  NULL,
    [import_hash]        NVARCHAR (64)  NULL,
    [processed]          BIT            NULL,
    [cleaned]            TINYINT        CONSTRAINT [DF_ds_zone_data_cleaned] DEFAULT ((0)) NOT NULL,
    [is_latest]          BIT            CONSTRAINT [DF_ds_zone_data_is_deleted] DEFAULT ((0)) NOT NULL,
    [is_held_for_review] BIT            CONSTRAINT [DF_ds_zone_data_is_held_for_review] DEFAULT ((0)) NOT NULL,
    [hash]               BINARY (16)    NULL,
    [index_hash]         BINARY (16)    NULL,
    [created_on]         DATETIME       CONSTRAINT [DF_ds_import_zone_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]         INT            CONSTRAINT [DF_ds_import_zone_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]     DATETIME       CONSTRAINT [DF_ds_import_zone_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]     INT            CONSTRAINT [DF_ds_import_zone_data_last_update_by] DEFAULT ((0)) NOT NULL,
    [archive]            BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ds_import_zone_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PT_ds_zone_data]
    ON [dbo].[ds_zone_data]([zone_id] ASC, [metric_id] ASC, [attribute_id] ASC, [date] ASC, [val_d] ASC, [val_i] ASC, [currency_id] ASC, [privacy_id] ASC);


GO
CREATE NONCLUSTERED INDEX [PT_ds_zone_data_created_update_on]
    ON [dbo].[ds_zone_data]([created_on] ASC, [last_update_on] ASC);

