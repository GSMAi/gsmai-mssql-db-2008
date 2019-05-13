CREATE TABLE [dbo].[metric_families] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [order]          INT            NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_metric_families_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_metric_families_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       NULL,
    [last_update_by] INT            NULL,
    CONSTRAINT [PK_metric_families] PRIMARY KEY CLUSTERED ([id] ASC)
);

