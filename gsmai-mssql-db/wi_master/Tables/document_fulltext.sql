CREATE TABLE [dbo].[document_fulltext] (
    [document_id]    INT            NOT NULL,
    [title]          NVARCHAR (512) NULL,
    [fulltext]       NVARCHAR (MAX) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_document_fulltext_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_document_fulltext_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_document_fulltext_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_document_fulltext_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_document_fulltext] PRIMARY KEY CLUSTERED ([document_id] ASC)
);

