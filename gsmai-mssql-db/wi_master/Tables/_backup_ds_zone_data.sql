CREATE TABLE [dbo].[_backup_ds_zone_data] (
    [id]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [zone_id]        INT             NOT NULL,
    [metric_id]      INT             NOT NULL,
    [attribute_id]   INT             NOT NULL,
    [status_id]      INT             CONSTRAINT [DF_ds_zone_data_status_id] DEFAULT ((3)) NOT NULL,
    [privacy_id]     INT             CONSTRAINT [DF_ds_zone_data_privacy_id] DEFAULT ((5)) NOT NULL,
    [date]           DATETIME        NOT NULL,
    [date_type]      CHAR (1)        NOT NULL,
    [val_d]          DECIMAL (22, 4) NULL,
    [val_i]          BIGINT          NULL,
    [currency_id]    INT             NOT NULL,
    [source_id]      INT             NOT NULL,
    [confidence_id]  INT             NOT NULL,
    [has_flags]      BIT             CONSTRAINT [DF_ds_zone_data_has_flags] DEFAULT ((0)) NOT NULL,
    [is_calculated]  BIT             CONSTRAINT [DF_ds_zone_data_is_calculated] DEFAULT ((0)) NOT NULL,
    [is_spot]        BIT             NULL,
    [import_id]      BIGINT          NULL,
    [created_on]     DATETIME        CONSTRAINT [DF_ds_zone_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             CONSTRAINT [DF_ds_zone_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        CONSTRAINT [DF_ds_zone_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT             CONSTRAINT [DF_ds_zone_data_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ds_zone_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ds_zone_data_metric_id]
    ON [dbo].[_backup_ds_zone_data]([metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ds_zone_data_zone_id]
    ON [dbo].[_backup_ds_zone_data]([zone_id] ASC, [metric_id] ASC, [attribute_id] ASC, [date_type] ASC, [date] ASC);

