CREATE FULLTEXT INDEX ON [dbo].[document_fulltext]
    ([title] LANGUAGE 1033, [fulltext] LANGUAGE 1033)
    KEY INDEX [PK_document_fulltext]
    ON [search_documents];


GO
CREATE FULLTEXT INDEX ON [dbo].[content_entries]
    ([title] LANGUAGE 1033, [subtitle] LANGUAGE 1033, [body] LANGUAGE 1033)
    KEY INDEX [PK_content_entries]
    ON [search];


GO
CREATE FULLTEXT INDEX ON [dbo].[feed]
    ([entry] LANGUAGE 0)
    KEY INDEX [PK_feed]
    ON [search];


GO
CREATE FULLTEXT INDEX ON [dbo].[search]
    ([term] LANGUAGE 0)
    KEY INDEX [PK_search]
    ON [search];

