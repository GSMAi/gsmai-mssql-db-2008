CREATE TABLE [dbo].[document_tag_link] (
    [document_id] INT NOT NULL,
    [tag_id]      INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_document_tag_document_id]
    ON [dbo].[document_tag_link]([document_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_document_tag_tag_id]
    ON [dbo].[document_tag_link]([tag_id] ASC);

