CREATE TABLE [dbo].[flags] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [definition]     NVARCHAR (MAX) NOT NULL,
    [order]          INT            NULL,
    [publish]        BIT            CONSTRAINT [DF_flags_publish] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_flags_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_flags_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_flags_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_flags_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_flags] PRIMARY KEY CLUSTERED ([id] ASC)
);

