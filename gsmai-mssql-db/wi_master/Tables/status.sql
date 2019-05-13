CREATE TABLE [dbo].[status] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [term]           NVARCHAR (MAX) NULL,
    [published]      BIT            CONSTRAINT [DF_status_published] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_status_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_status_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_status_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_status_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_status] PRIMARY KEY CLUSTERED ([id] ASC)
);

