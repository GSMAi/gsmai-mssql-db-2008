CREATE TABLE [dbo].[blog_entry_tag_link] (
    [entry_id] INT NOT NULL,
    [tag_id]   INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_blog_entry_tag_link_entry_id]
    ON [dbo].[blog_entry_tag_link]([entry_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_blog_entry_tag_link_tag_id]
    ON [dbo].[blog_entry_tag_link]([tag_id] ASC);

