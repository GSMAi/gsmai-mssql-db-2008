CREATE TABLE [dbo].[wiki_entries] (
    [id]             INT            NOT NULL,
    [wiki_id]        INT            NOT NULL,
    [category_id]    INT            NOT NULL,
    [title]          NVARCHAR (512) NULL,
    [permalink]      NVARCHAR (512) NULL,
    [body]           NVARCHAR (MAX) NOT NULL,
    [status]         TINYINT        CONSTRAINT [DF_wiki_entries_status] DEFAULT ((1)) NOT NULL,
    [order]          INT            NULL,
    [published_on]   DATETIME       CONSTRAINT [DF_wiki_entries_published_on] DEFAULT (getdate()) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_wiki_entries_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_wiki_entries_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_wiki_entries_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_wiki_entries_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wiki_entries_1] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_wiki_entries]
    ON [dbo].[wiki_entries]([wiki_id] ASC, [category_id] ASC);

