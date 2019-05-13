CREATE TABLE [dbo].[blog_entries] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [blog_id]        INT            NOT NULL,
    [title]          NVARCHAR (512) NOT NULL,
    [subtitle]       NVARCHAR (512) NULL,
    [permalink]      NVARCHAR (512) NOT NULL,
    [preview]        NVARCHAR (MAX) NULL,
    [body]           NVARCHAR (MAX) NOT NULL,
    [status]         TINYINT        CONSTRAINT [DF_blog_entries_status] DEFAULT ((1)) NOT NULL,
    [is_stub]        BIT            CONSTRAINT [DF_Table_1_stub] DEFAULT ((0)) NOT NULL,
    [is_search_only] BIT            CONSTRAINT [DF_Table_1_search_only] DEFAULT ((0)) NOT NULL,
    [published_on]   DATETIME       CONSTRAINT [DF_blog_entries_published_on] DEFAULT (getdate()) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_blog_entries_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_blog_entries_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_blog_entries_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_blog_entries_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_blog_entries] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_blog_entries]
    ON [dbo].[blog_entries]([blog_id] ASC, [published_on] DESC);

