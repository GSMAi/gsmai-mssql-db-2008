CREATE TABLE [dbo].[source_folders] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [source_type_id] INT            NOT NULL,
    [type_id]        INT            NULL,
    [path]           NVARCHAR (MAX) NOT NULL,
    [name]           NVARCHAR (MAX) NOT NULL,
    [is_orphaned]    BIT            CONSTRAINT [DF_source_folders_is_orphaned] DEFAULT ((0)) NOT NULL,
    [is_private]     BIT            CONSTRAINT [DF_source_folders_is_private] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_source_folders_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_source_folders_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_source_folders] PRIMARY KEY CLUSTERED ([id] ASC)
);

