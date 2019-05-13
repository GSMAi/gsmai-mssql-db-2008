CREATE TABLE [dbo].[ds_mvnos] (
    [id]                    INT             IDENTITY (1, 1) NOT NULL,
    [mvno_id]               INT             NOT NULL,
    [category_id]           INT             NULL,
    [tariff_type_id]        INT             CONSTRAINT [DF_ds_mvnos_tariff_type_id] DEFAULT ((-3)) NOT NULL,
    [launch_date]           DATETIME        NULL,
    [url]                   NVARCHAR (1024) NULL,
    [is_brand]              BIT             CONSTRAINT [DF_ds_mvnos_is_brand] DEFAULT ((0)) NOT NULL,
    [is_data_only]          BIT             CONSTRAINT [DF_ds_mvnos_is_data_only] DEFAULT ((0)) NOT NULL,
    [has_data]              BIT             CONSTRAINT [DF_ds_mvnos_has_data] DEFAULT ((0)) NOT NULL,
    [has_group_data]        BIT             CONSTRAINT [DF_ds_mvnos_has_group_data] DEFAULT ((0)) NOT NULL,
    [created_on]            DATETIME        CONSTRAINT [DF_ds_mvnos_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]            INT             CONSTRAINT [DF_ds_mvnos_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]        DATETIME        CONSTRAINT [DF_ds_mvnos_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]        INT             CONSTRAINT [DF_ds_mvnos_last_update_by] DEFAULT ((0)) NOT NULL,
    [is_branded_reseller]   BIT             DEFAULT ((0)) NOT NULL,
    [full_mvno]             BIT             DEFAULT ((0)) NOT NULL,
    [note]                  NVARCHAR (2048) NULL,
    [secondary_category_id] INT             NULL,
    CONSTRAINT [PK_ds_mvnos] PRIMARY KEY CLUSTERED ([id] ASC)
);

