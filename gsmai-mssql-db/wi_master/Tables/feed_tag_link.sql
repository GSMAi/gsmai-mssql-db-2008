CREATE TABLE [dbo].[feed_tag_link] (
    [feed_id] INT NOT NULL,
    [tag_id]  INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_feed_tag_link_feed_id]
    ON [dbo].[feed_tag_link]([feed_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_feed_tag_link_tag_id]
    ON [dbo].[feed_tag_link]([tag_id] ASC);

