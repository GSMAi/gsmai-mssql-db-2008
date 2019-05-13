CREATE TABLE [dbo].[feed_entity_link] (
    [feed_id]   INT           NOT NULL,
    [entity_id] INT           NOT NULL,
    [table]     NVARCHAR (64) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_feed_entity_link_entity_id]
    ON [dbo].[feed_entity_link]([entity_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_feed_entity_link_feed_id]
    ON [dbo].[feed_entity_link]([feed_id] ASC);

