CREATE TABLE [dbo].[api_keys] (
    [id]              INT              IDENTITY (1, 1) NOT NULL,
    [key]             UNIQUEIDENTIFIER NOT NULL,
    [organisation_id] INT              NOT NULL,
    [domain]          NVARCHAR (1024)  NULL,
    [status]          BIT              CONSTRAINT [DF_api_keys_status] DEFAULT ((1)) NOT NULL,
    [allow_apis]      BIT              CONSTRAINT [DF_api_keys_allow_apis] DEFAULT ((1)) NOT NULL,
    [allow_queries]   BIT              CONSTRAINT [DF_api_keys_allow_queries] DEFAULT ((1)) NOT NULL,
    [allow_sso]       BIT              CONSTRAINT [DF_api_keys_allow_sso] DEFAULT ((0)) NOT NULL,
    [note]            NVARCHAR (512)   NULL,
    [created_on]      DATETIME         CONSTRAINT [DF_api_keys_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]      INT              CONSTRAINT [DF_api_keys_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_api_keys] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_api_keys]
    ON [dbo].[api_keys]([key] ASC, [organisation_id] ASC);

