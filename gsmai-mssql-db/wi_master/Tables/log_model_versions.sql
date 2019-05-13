CREATE TABLE [dbo].[log_model_versions] (
    [id]         INT        IDENTITY (1, 1) NOT NULL,
    [zone_id]    INT        NOT NULL,
    [version]    FLOAT (53) NOT NULL,
    [created_on] DATETIME   CONSTRAINT [DF_log_model_versions_created_on] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_log_model_versions] PRIMARY KEY CLUSTERED ([id] ASC)
);

