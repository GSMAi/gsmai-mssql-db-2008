CREATE TABLE [dbo].[blog_entry_user_link] (
    [entry_id] INT NOT NULL,
    [user_id]  INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_blog_entry_user_link_entry_id]
    ON [dbo].[blog_entry_user_link]([entry_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_blog_entry_user_link_user_id]
    ON [dbo].[blog_entry_user_link]([user_id] ASC);

