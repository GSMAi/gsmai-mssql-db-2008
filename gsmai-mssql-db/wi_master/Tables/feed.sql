CREATE TABLE [dbo].[feed] (
    [id]               INT             IDENTITY (1, 1) NOT NULL,
    [zone_id]          INT             NULL,
    [organisation_id]  INT             NULL,
    [entry]            NVARCHAR (MAX)  NULL,
    [source]           NVARCHAR (MAX)  NULL,
    [url]              NVARCHAR (1024) NULL,
    [status]           BIT             CONSTRAINT [DF_feed_status] DEFAULT ((0)) NOT NULL,
    [has_image]        BIT             CONSTRAINT [DF_feed_has_image] DEFAULT ((0)) NOT NULL,
    [thumbnail_width]  INT             NULL,
    [thumbnail_height] INT             NULL,
    [is_meta]          BIT             CONSTRAINT [DF_feed_is_meta] DEFAULT ((0)) NOT NULL,
    [is_action]        BIT             CONSTRAINT [DF_feed_is_actionable] DEFAULT ((0)) NOT NULL,
    [is_analysis]      BIT             CONSTRAINT [DF_feed_is_analysis] DEFAULT ((0)) NOT NULL,
    [is_private]       BIT             CONSTRAINT [DF_feed_is_private] DEFAULT ((0)) NOT NULL,
    [published]        BIT             CONSTRAINT [DF_feed_published] DEFAULT ((0)) NOT NULL,
    [created_on]       DATETIME        CONSTRAINT [DF_feed_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]       INT             CONSTRAINT [DF_feed_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]   DATETIME        CONSTRAINT [DF_feed_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]   INT             CONSTRAINT [DF_feed_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_feed] PRIMARY KEY CLUSTERED ([id] ASC)
);

