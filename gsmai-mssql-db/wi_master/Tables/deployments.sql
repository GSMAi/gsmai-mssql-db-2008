CREATE TABLE [dbo].[deployments] (
    [id]             INT             IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512)  NOT NULL,
    [status_id]      INT             CONSTRAINT [DF_products_status_id] DEFAULT ((0)) NOT NULL,
    [url]            NVARCHAR (1024) NULL,
    [description]    NVARCHAR (MAX)  NULL,
    [note]           NVARCHAR (MAX)  NULL,
    [created_on]     DATETIME        CONSTRAINT [DF_products_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             CONSTRAINT [DF_products_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        NULL,
    [last_update_by] INT             NULL,
    CONSTRAINT [PK_products] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_deployments_attributes] FOREIGN KEY ([status_id]) REFERENCES [dbo].[attributes] ([id])
);

