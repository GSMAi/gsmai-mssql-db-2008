CREATE TABLE [dbo].[fields] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_fields_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_fields_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       NULL,
    [last_update_by] INT            NULL,
    CONSTRAINT [PK_fields] PRIMARY KEY CLUSTERED ([id] ASC)
);

