CREATE TABLE [dbo].[metrics] (
    [id]                    INT            IDENTITY (1, 1) NOT NULL,
    [name]                  NVARCHAR (512) NOT NULL,
    [term]                  NVARCHAR (MAX) NULL,
    [type_id]               INT            NULL,
    [unit_id]               INT            NULL,
    [currency_based]        BIT            NULL,
    [has_attributes]        BIT            CONSTRAINT [DF_metrics_has_attributes] DEFAULT ((1)) NULL,
    [order]                 INT            NULL,
    [published]             BIT            CONSTRAINT [DF_metrics_published] DEFAULT ((0)) NULL,
    [created_on]            DATETIME       CONSTRAINT [DF_metric_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]            INT            CONSTRAINT [DF_metric_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]        DATETIME       CONSTRAINT [DF_metric_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]        INT            CONSTRAINT [DF_metric_last_update_by] DEFAULT ((0)) NOT NULL,
    [parent_metric_type_id] INT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_metrics] PRIMARY KEY CLUSTERED ([id] ASC)
);

