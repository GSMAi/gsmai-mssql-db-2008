CREATE TABLE [dbo].[favourite_user_link] (
    [favourite_id] INT      NOT NULL,
    [user_id]      INT      NOT NULL,
    [created_on]   DATETIME CONSTRAINT [DF_favourite_user_link_created_on] DEFAULT (getdate()) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_favourite_user_link]
    ON [dbo].[favourite_user_link]([user_id] ASC, [favourite_id] ASC);

