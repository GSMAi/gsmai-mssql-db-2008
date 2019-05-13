CREATE TABLE [dbo].[cache] (
    [id]         BIGINT         NOT NULL,
    [sp]         NVARCHAR (128) NOT NULL,
    [hash]       VARCHAR (32)   NOT NULL,
    [type]       VARCHAR (8)    NOT NULL,
    [created_on] DATETIME       DEFAULT (getdate()) NOT NULL,
    [created_by] INT            DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_cache]
    ON [dbo].[cache]([id] ASC, [type] ASC);

