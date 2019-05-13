CREATE TABLE [dbo].[currencies] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [iso_code]       NVARCHAR (50)  NULL,
    [note]           NVARCHAR (512) NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_currencies_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_currencies_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_currencies_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_currencies_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_currencies] PRIMARY KEY CLUSTERED ([id] ASC)
);

