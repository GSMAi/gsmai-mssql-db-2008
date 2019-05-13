CREATE TABLE [dbo].[subscription_domain_link] (
    [id]              INT             IDENTITY (1, 1) NOT NULL,
    [subscription_id] INT             NOT NULL,
    [domain]          NVARCHAR (1024) NOT NULL,
    [created_on]      DATETIME        CONSTRAINT [DF_subscription_domain_link_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]      INT             CONSTRAINT [DF_subscription_domain_link_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_subscription_domain_link] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_subscription_domain_link]
    ON [dbo].[subscription_domain_link]([subscription_id] ASC);

