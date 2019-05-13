CREATE TABLE [dbo].[search] (
    [id]                INT            IDENTITY (1, 1) NOT NULL,
    [scheme_entity_id]  NVARCHAR (128) NOT NULL,
    [entity_id]         INT            NOT NULL,
    [entity_type]       NVARCHAR (64)  NULL,
    [term]              NVARCHAR (256) NOT NULL,
    [metadata]          NVARCHAR (256) NULL,
    [table]             NVARCHAR (64)  NOT NULL,
    [order]             INT            CONSTRAINT [DF_search_order] DEFAULT ((0)) NOT NULL,
    [is_alternate_term] BIT            CONSTRAINT [DF_search_is_alternate_term] DEFAULT ((0)) NOT NULL,
    [has_data]          BIT            CONSTRAINT [DF_search_has_data] DEFAULT ((0)) NOT NULL,
    [has_content]       BIT            CONSTRAINT [DF_search_has_content] DEFAULT ((0)) NOT NULL,
    [has_blogs]         BIT            CONSTRAINT [DF_search_has_blog_items] DEFAULT ((0)) NOT NULL,
    [has_documents]     BIT            CONSTRAINT [DF_search_has_documents] DEFAULT ((0)) NOT NULL,
    [has_feeds]         BIT            CONSTRAINT [DF_search_has_feed_items] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_search] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_search_scheme_entity_id]
    ON [dbo].[search]([scheme_entity_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_search_term]
    ON [dbo].[search]([term] ASC);

