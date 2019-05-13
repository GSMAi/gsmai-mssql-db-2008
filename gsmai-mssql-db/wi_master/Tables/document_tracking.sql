CREATE TABLE [dbo].[document_tracking] (
    [id]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [document_id] INT      NOT NULL,
    [user_id]     INT      NOT NULL,
    [created_on]  DATETIME CONSTRAINT [DF_document_tracking_created_on] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_document_tracking] PRIMARY KEY CLUSTERED ([id] ASC)
);

