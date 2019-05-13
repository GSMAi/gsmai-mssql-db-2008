CREATE TABLE [dbo].[feedback] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [subject]        NVARCHAR (MAX) NOT NULL,
    [entry]          NVARCHAR (MAX) NOT NULL,
    [is_bug]         BIT            CONSTRAINT [DF_feedback_is_bug] DEFAULT ((0)) NOT NULL,
    [status]         TINYINT        CONSTRAINT [DF_feedback_status] DEFAULT ((1)) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_feedback_created_by] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_feedback_created_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_feedback_last_update_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_feedback_last_update_on] DEFAULT (getdate()) NOT NULL
);

