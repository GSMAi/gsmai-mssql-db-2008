CREATE TABLE [dbo].[df_service_data] (
    [deployment_id]  INT             NOT NULL,
    [field_id]       INT             NOT NULL,
    [status_id]      INT             CONSTRAINT [DF_df_service_data_status_id] DEFAULT ((3)) NOT NULL,
    [privacy_id]     INT             CONSTRAINT [DF_df_service_data_privacy_id] DEFAULT ((5)) NOT NULL,
    [value]          VARBINARY (MAX) NOT NULL,
    [currency_id]    INT             NULL,
    [created_on]     DATETIME        CONSTRAINT [DF_df_service_data_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             CONSTRAINT [DF_df_service_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        NULL,
    [last_update_by] INT             NULL,
    CONSTRAINT [FK_df_service_data_attributes_privacy] FOREIGN KEY ([privacy_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_df_service_data_attributes_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [FK_df_service_data_currencies] FOREIGN KEY ([currency_id]) REFERENCES [dbo].[currencies] ([id])
);

