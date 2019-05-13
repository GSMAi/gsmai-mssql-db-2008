CREATE TABLE [dbo].[privacy] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [term]           NVARCHAR (MAX) NULL,
    [published]      BIT            CONSTRAINT [DF_privacy_published] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_privacy_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_privacy_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_privacy_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_privacy_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_privacy] PRIMARY KEY CLUSTERED ([id] ASC)
);

