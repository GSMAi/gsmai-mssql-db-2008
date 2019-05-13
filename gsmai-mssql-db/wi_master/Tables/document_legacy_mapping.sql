CREATE TABLE [dbo].[document_legacy_mapping] (
    [id]         INT            IDENTITY (1, 1) NOT NULL,
    [entry_id]   INT            NOT NULL,
    [filename]   NVARCHAR (256) NOT NULL,
    [hash]       VARCHAR (64)   NOT NULL,
    [created_on] DATETIME       CONSTRAINT [DF_document_legacy_mapping_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT            CONSTRAINT [DF_document_legacy_mapping_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_document_legacy_mapping] PRIMARY KEY CLUSTERED ([id] ASC)
);

