CREATE TABLE [dbo].[files] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [type_id]        INT            NOT NULL,
    [subtype_id]     INT            NULL,
    [folder]         NVARCHAR (256) NOT NULL,
    [file]           NVARCHAR (256) NOT NULL,
    [file_extension] NVARCHAR (32)  NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_files_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_files_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_files] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_files]
    ON [dbo].[files]([folder] ASC);

