CREATE TABLE [dbo].[ds_service_data] (
    [id]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [service_id]     INT             NOT NULL,
    [metric_id]      INT             NOT NULL,
    [attribute_id]   INT             NOT NULL,
    [date]           DATETIME        NOT NULL,
    [date_type]      CHAR (1)        NOT NULL,
    [val_d]          DECIMAL (22, 4) NULL,
    [val_i]          BIGINT          NULL,
    [currency_id]    INT             NOT NULL,
    [source_id]      INT             NOT NULL,
    [confidence_id]  INT             NOT NULL,
    [status_id]      INT             NOT NULL,
    [privacy_id]     INT             NOT NULL,
    [has_flags]      BIT             CONSTRAINT [DF_ds_service_data_has_flags] DEFAULT ((0)) NOT NULL,
    [notes]          NVARCHAR (MAX)  NULL,
    [approved]       TINYINT         NULL,
    [approval_hash]  NVARCHAR (64)   NULL,
    [import_hash]    NVARCHAR (64)   NULL,
    [processed]      BIT             NULL,
    [hash]           BINARY (16)     NULL,
    [index_hash]     BINARY (16)     NULL,
    [created_on]     DATETIME        CONSTRAINT [DF_ds_service_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             CONSTRAINT [DF_ds_service_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        NULL,
    [last_update_by] INT             NULL,
    CONSTRAINT [PK_ds_service_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ds_service_data_import_hash]
    ON [dbo].[ds_service_data]([import_hash] ASC);

