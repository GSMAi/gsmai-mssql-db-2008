CREATE TABLE [dbo].[ds_zone_forecast_data] (
    [id]             BIGINT          IDENTITY (1, 1) NOT NULL,
    [zone_id]        INT             NOT NULL,
    [metric_id]      INT             NOT NULL,
    [attribute_id]   INT             NULL,
    [date]           DATETIME        NOT NULL,
    [date_type]      CHAR (1)        NOT NULL,
    [val_d]          DECIMAL (22, 4) NULL,
    [val_i]          BIGINT          NULL,
    [currency_id]    INT             NOT NULL,
    [source_id]      INT             NOT NULL,
    [confidence_id]  INT             NOT NULL,
    [privacy_id]     INT             NULL,
    [approved]       TINYINT         CONSTRAINT [DF_ds_zone_forecast_data_approved] DEFAULT (NULL) NULL,
    [approval_hash]  NVARCHAR (64)   NULL,
    [import_hash]    NVARCHAR (64)   NULL,
    [hash]           INT             NULL,
    [created_on]     DATETIME        CONSTRAINT [DF_ds_zone_forecast_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             CONSTRAINT [DF_ds_zone_forecast_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        CONSTRAINT [DF_ds_zone_forecast_data_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT             CONSTRAINT [DF_ds_zone_forecast_data_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ds_zone_forecast_data] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PT_ds_zone_forecast_data]
    ON [dbo].[ds_zone_forecast_data]([zone_id] ASC, [metric_id] ASC, [attribute_id] ASC, [date] ASC, [val_d] ASC, [val_i] ASC, [currency_id] ASC, [privacy_id] ASC);


GO
CREATE NONCLUSTERED INDEX [PT_ds_zone_forecast_data_created_update_on]
    ON [dbo].[ds_zone_forecast_data]([created_on] ASC, [last_update_on] ASC);

