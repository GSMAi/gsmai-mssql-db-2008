CREATE TABLE [dbo].[report_favourites] (
    [id]         BIGINT       IDENTITY (1, 1) NOT NULL,
    [report_id]  INT          NOT NULL,
    [user_id]    INT          NOT NULL,
    [type]       VARCHAR (16) NOT NULL,
    [created_on] DATETIME     CONSTRAINT [DF_report_favourites_created_on] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_report_favourites] PRIMARY KEY CLUSTERED ([id] ASC)
);

