CREATE TABLE [dbo].[source_organisation_link] (
    [id]              INT            IDENTITY (1, 1) NOT NULL,
    [name]            NVARCHAR (512) NOT NULL,
    [term]            NVARCHAR (MAX) NOT NULL,
    [organisation_id] INT            NOT NULL,
    [description]     NVARCHAR (MAX) NULL,
    [created_on]      DATETIME       CONSTRAINT [DF_source_organisation_link_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]      INT            CONSTRAINT [DF_source_organisation_link_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_source_organisation_link] PRIMARY KEY CLUSTERED ([id] ASC)
);

