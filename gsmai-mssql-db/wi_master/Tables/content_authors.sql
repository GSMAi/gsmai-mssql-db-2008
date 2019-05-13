CREATE TABLE [dbo].[content_authors] (
    [id]            INT            IDENTITY (1, 1) NOT NULL,
    [user_id]       INT            NULL,
    [name]          NVARCHAR (512) NULL,
    [url]           NVARCHAR (128) NULL,
    [job_title]     NVARCHAR (512) NULL,
    [biography]     NVARCHAR (MAX) NULL,
    [show_in_team]  BIT            CONSTRAINT [DF_content_authors_show_in_team] DEFAULT ((0)) NOT NULL,
    [date_joined]   DATETIME       NULL,
    [date_retired]  DATETIME       NULL,
    [statistics]    NVARCHAR (MAX) NULL,
    [created_on]    DATETIME       CONSTRAINT [DF_content_authors_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]    INT            CONSTRAINT [DF_content_authors_created_by] DEFAULT ((0)) NOT NULL,
    [confluence_id] INT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_content_authors] PRIMARY KEY CLUSTERED ([id] ASC)
);

