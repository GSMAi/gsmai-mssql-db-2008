CREATE TABLE [dbo].[content_entry_author_link] (
    [entry_id]       INT NOT NULL,
    [author_id]      INT NOT NULL,
    [is_contributor] BIT CONSTRAINT [DF_content_entry_author_link_is_contributor] DEFAULT ((0)) NOT NULL
);

