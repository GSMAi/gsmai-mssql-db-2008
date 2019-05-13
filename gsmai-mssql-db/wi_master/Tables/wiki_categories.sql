CREATE TABLE [dbo].[wiki_categories] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [wiki_id]        INT            NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [order]          INT            NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_wiki_categories_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_wiki_categories_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_wiki_categories_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_wiki_categories_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wiki_categories] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_wiki_categories]
    ON [dbo].[wiki_categories]([wiki_id] ASC);

