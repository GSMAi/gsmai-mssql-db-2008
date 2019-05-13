CREATE TABLE [dbo].[content_entry_links] (
    [entry_id]   INT             NOT NULL,
    [title]      NVARCHAR (1024) NOT NULL,
    [set]        NVARCHAR (1024) NULL,
    [url]        NVARCHAR (1024) NOT NULL,
    [order]      INT             CONSTRAINT [DF_content_entry_links_order] DEFAULT ((0)) NOT NULL,
    [created_on] DATETIME        CONSTRAINT [DF_content_entry_links_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT             CONSTRAINT [DF_content_entry_links_created_by] DEFAULT ((0)) NOT NULL
);

