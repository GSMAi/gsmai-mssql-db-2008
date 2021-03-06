﻿CREATE TABLE [dbo].[ds_service_data] (
    [id]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [service_id]        INT             NOT NULL,
    [metric_id]         INT             NOT NULL,
    [attribute_id]      INT             NOT NULL,
    [status_id]         INT             CONSTRAINT [DF_ds_service_data_status_id] DEFAULT ((3)) NOT NULL,
    [privacy_id]        INT             CONSTRAINT [DF_ds_service_data_privacy_id] DEFAULT ((5)) NOT NULL,
    [date]              DATETIME        NOT NULL,
    [date_type]         CHAR (1)        NOT NULL,
    [val_d]             DECIMAL (22, 4) NULL,
    [val_i]             BIGINT          NULL,
    [currency_id]       INT             NOT NULL,
    [source_id]         INT             NOT NULL,
    [confidence_id]     INT             NOT NULL,
    [has_flags]         BIT             CONSTRAINT [DF_ds_service_data_has_flags] DEFAULT ((0)) NOT NULL,
    [is_calculated]     BIT             CONSTRAINT [DF_ds_service_data_is_calculated] DEFAULT ((0)) NOT NULL,
    [import_id]         BIGINT          NULL,
    [import_merge_hash] NVARCHAR (64)   NULL,
    [created_on]        DATETIME        CONSTRAINT [DF_ds_service_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]        INT             CONSTRAINT [DF_ds_service_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]    DATETIME        NULL,
    [last_update_by]    INT             NULL,
    CONSTRAINT [PK_ds_service_data] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_ds_service_data_attributes] FOREIGN KEY ([attribute_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_ds_service_data_attributes_confidence] FOREIGN KEY ([confidence_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_ds_service_data_attributes_privacy] FOREIGN KEY ([privacy_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_ds_service_data_attributes_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_ds_service_data_currencies] FOREIGN KEY ([currency_id]) REFERENCES [dbo].[currencies] ([id]),
    CONSTRAINT [FK_ds_service_data_deployments] FOREIGN KEY ([service_id]) REFERENCES [dbo].[deployments] ([id]),
    CONSTRAINT [FK_ds_service_data_metrics] FOREIGN KEY ([metric_id]) REFERENCES [dbo].[metrics] ([id]),
    CONSTRAINT [FK_ds_service_data_sources] FOREIGN KEY ([source_id]) REFERENCES [dbo].[sources] ([id])
);

