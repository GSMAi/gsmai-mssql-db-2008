CREATE TABLE [dbo].[tags] (
    [id]   INT            IDENTITY (1, 1) NOT NULL,
    [name] NVARCHAR (100) NOT NULL,
    [url]  NVARCHAR (100) NULL,
    CONSTRAINT [PK_tags] PRIMARY KEY CLUSTERED ([id] ASC)
);

