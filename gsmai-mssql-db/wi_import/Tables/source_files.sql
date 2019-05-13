CREATE TABLE [dbo].[source_files] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [source_type_id] INT            NOT NULL,
    [type_id]        INT            NULL,
    [path]           NVARCHAR (MAX) NOT NULL,
    [name]           NVARCHAR (MAX) NOT NULL,
    [extension]      NVARCHAR (32)  NOT NULL,
    [mime_type]      NVARCHAR (128) NOT NULL,
    [pages]          INT            NULL,
    [size]           INT            NULL,
    [hash]           VARCHAR (64)   NOT NULL,
    [is_orphaned]    BIT            CONSTRAINT [DF_source_files_is_orphaned] DEFAULT ((0)) NOT NULL,
    [is_private]     BIT            CONSTRAINT [DF_source_files_is_private] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_source_files_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_source_files_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_source_files] PRIMARY KEY CLUSTERED ([id] ASC)
);

