CREATE TABLE [dbo].[ds_mvnos] (
    [id]                    INT             NOT NULL,
    [mvno_id]               INT             NOT NULL,
    [category_id]           INT             NULL,
    [tariff_type_id]        INT             NOT NULL,
    [launch_date]           DATETIME        NULL,
    [url]                   NVARCHAR (1024) NULL,
    [is_brand]              BIT             NOT NULL,
    [is_data_only]          BIT             NOT NULL,
    [has_data]              BIT             NOT NULL,
    [has_group_data]        BIT             NOT NULL,
    [created_on]            DATETIME        NOT NULL,
    [created_by]            INT             NOT NULL,
    [last_update_on]        DATETIME        NOT NULL,
    [last_update_by]        INT             NOT NULL,
    [is_branded_reseller]   BIT             NOT NULL,
    [full_mvno]             BIT             NOT NULL,
    [note]                  NVARCHAR (2048) NULL,
    [secondary_category_id] INT             NULL,
    [inserted_on]           DATETIME        NOT NULL
);

