CREATE TABLE [dbo].[news] (
    [id]           INT             IDENTITY (1, 1) NOT NULL,
    [title]        NVARCHAR (512)  NOT NULL,
    [guid]         NVARCHAR (1024) NOT NULL,
    [url]          NVARCHAR (1024) NOT NULL,
    [body]         NVARCHAR (MAX)  NULL,
    [type]         TINYINT         CONSTRAINT [DF_news_type] DEFAULT ((0)) NOT NULL,
    [published_on] DATETIME        NOT NULL,
    [created_on]   DATETIME        CONSTRAINT [DF_news_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]   INT             CONSTRAINT [DF_news_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_news] PRIMARY KEY CLUSTERED ([id] ASC)
);

