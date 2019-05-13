CREATE TABLE [dbo].[wikis] (
    [id]         INT             IDENTITY (1, 1) NOT NULL,
    [name]       NVARCHAR (512)  NOT NULL,
    [url]        NVARCHAR (1024) NOT NULL,
    [created_on] DATETIME        CONSTRAINT [DF_wikis_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT             CONSTRAINT [DF_wikis_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wikis] PRIMARY KEY CLUSTERED ([id] ASC)
);

