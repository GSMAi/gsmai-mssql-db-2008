CREATE TABLE [dbo].[auction_awards] (
    [id]                    INT             IDENTITY (1, 1) NOT NULL,
    [auction_id]            INT             NOT NULL,
    [organisation_id]       INT             NOT NULL,
    [status_id]             INT             NOT NULL,
    [duration]              INT             NULL,
    [duration_extension]    INT             NULL,
    [issue_date]            DATETIME        NULL,
    [expiry_date]           DATETIME        NULL,
    [block]                 DECIMAL (22, 4) NULL,
    [block_paired]          DECIMAL (22, 4) NULL,
    [block_unpaired]        DECIMAL (22, 4) NULL,
    [downlink_band]         NVARCHAR (MAX)  NULL,
    [uplink_band]           NVARCHAR (MAX)  NULL,
    [note]                  NVARCHAR (MAX)  NULL,
    [obligations]           NVARCHAR (MAX)  NULL,
    [terms]                 NVARCHAR (MAX)  NULL,
    [price]                 DECIMAL (22, 4) NULL,
    [price_usd]             DECIMAL (22, 4) NULL,
    [price_per_mhz]         DECIMAL (22, 4) NULL,
    [price_per_mhz_usd]     DECIMAL (22, 4) NULL,
    [price_per_mhz_usd_ppp] DECIMAL (22, 4) NULL,
    [price_currency_id]     INT             NULL,
    [reserve]               DECIMAL (22, 4) NULL,
    [reserve_currency_id]   INT             NULL,
    [created_on]            DATETIME        CONSTRAINT [DF_auction_awards_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]            INT             CONSTRAINT [DF_auction_awards_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]        DATETIME        CONSTRAINT [DF_auction_awards_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]        INT             CONSTRAINT [DF_auction_awards_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_auction_awards] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_auction_awards]
    ON [dbo].[auction_awards]([auction_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_auction_awards_organisation]
    ON [dbo].[auction_awards]([organisation_id] ASC);

