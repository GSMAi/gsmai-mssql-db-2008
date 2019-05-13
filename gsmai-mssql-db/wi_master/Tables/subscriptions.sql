CREATE TABLE [dbo].[subscriptions] (
    [id]                          INT            IDENTITY (1, 1) NOT NULL,
    [organisation_id]             INT            NOT NULL,
    [expiry]                      DATETIME       NOT NULL,
    [archived]                    BIT            CONSTRAINT [DF_subscriptions_archived] DEFAULT ((0)) NOT NULL,
    [suspended]                   BIT            CONSTRAINT [DF_subscriptions_suspended] DEFAULT ((0)) NOT NULL,
    [has_subscription]            BIT            CONSTRAINT [DF_subscriptions_has_subscription] DEFAULT ((1)) NOT NULL,
    [has_feed]                    BIT            CONSTRAINT [DF_subscriptions_has_feed] DEFAULT ((1)) NOT NULL,
    [is_commercial]               BIT            CONSTRAINT [DF_subscriptions_is_commercial] DEFAULT ((0)) NOT NULL,
    [default_role_id]             INT            CONSTRAINT [DF_subscriptions_default_role_id] DEFAULT ((3)) NOT NULL,
    [default_duration]            VARCHAR (16)   CONSTRAINT [DF_subscriptions_default_duration] DEFAULT ('P1Y') NOT NULL,
    [default_show_forecasts]      BIT            CONSTRAINT [DF_subscriptions_default_show_forecasts] DEFAULT ((1)) NOT NULL,
    [default_date_type]           CHAR (1)       CONSTRAINT [DF_subscriptions_default_date_type] DEFAULT ('Q') NOT NULL,
    [default_currency_id]         INT            CONSTRAINT [DF_subscriptions_default_currency_id] DEFAULT ((1)) NOT NULL,
    [default_currency_type]       BIT            CONSTRAINT [DF_subscriptions_default_currency_type_id] DEFAULT ((1)) NOT NULL,
    [default_local_currencies]    BIT            CONSTRAINT [DF_subscriptions_default_local_currencies] DEFAULT ((0)) NOT NULL,
    [default_geoscheme_id]        INT            CONSTRAINT [DF_subscriptions_default_geoscheme_id] DEFAULT ((3936)) NOT NULL,
    [enable_keyboard_shortcuts]   BIT            CONSTRAINT [DF_subscriptions_enable_keyboard_shortcuts] DEFAULT ((0)) NOT NULL,
    [note]                        NVARCHAR (MAX) NULL,
    [created_on]                  DATETIME       CONSTRAINT [DF_subscriptions_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]                  INT            CONSTRAINT [DF_subscriptions_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]              DATETIME       CONSTRAINT [DF_subscriptions_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]              INT            CONSTRAINT [DF_subscriptions_last_update_by] DEFAULT ((0)) NOT NULL,
    [with_multiplay_operator]     BIT            CONSTRAINT [DF_with_multiplay_operator] DEFAULT ((0)) NOT NULL,
    [with_multiplay_non_operator] BIT            CONSTRAINT [DF_with_multiplay_non_operator] DEFAULT ((0)) NOT NULL,
    [with_consumer_operator]      BIT            CONSTRAINT [DF_with_consumer_operator] DEFAULT ((0)) NOT NULL,
    [with_consumer_non_operator]  BIT            CONSTRAINT [DF_with_consumer_non_operator] DEFAULT ((0)) NOT NULL,
    [with_iot_operator]           BIT            CONSTRAINT [DF_with_iot_operator] DEFAULT ((0)) NOT NULL,
    [with_iot_non_operator]       BIT            CONSTRAINT [DF_with_iot_non_operator] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_subscriptions] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_subscriptions]
    ON [dbo].[subscriptions]([organisation_id] ASC);

