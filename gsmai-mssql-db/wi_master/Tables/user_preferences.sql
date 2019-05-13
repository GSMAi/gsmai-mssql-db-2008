CREATE TABLE [dbo].[user_preferences] (
    [user_id]                   INT          NOT NULL,
    [default_duration]          VARCHAR (16) CONSTRAINT [DF_user_preferences_default_duration] DEFAULT ('P1Y') NOT NULL,
    [default_show_forecasts]    BIT          CONSTRAINT [DF_user_preferences_show_forecasts] DEFAULT ((1)) NOT NULL,
    [default_date_type]         CHAR (1)     CONSTRAINT [DF_user_preferences_default_date_type] DEFAULT ('Q') NOT NULL,
    [default_currency_id]       INT          CONSTRAINT [DF_user_preferences_default_currency_id] DEFAULT ((1)) NOT NULL,
    [default_currency_type]     BIT          CONSTRAINT [DF_user_preferences_default_currency_type] DEFAULT ((1)) NOT NULL,
    [default_local_currencies]  BIT          CONSTRAINT [DF_user_preferences_default_local_currencies] DEFAULT ((0)) NOT NULL,
    [default_geoscheme_id]      INT          CONSTRAINT [DF_user_preferences_default_geoscheme_id] DEFAULT ((3936)) NOT NULL,
    [enable_keyboard_shortcuts] BIT          CONSTRAINT [DF_user_preferences_enable_keyboard_shortcuts] DEFAULT ((0)) NOT NULL,
    [receive_email]             BIT          CONSTRAINT [DF_user_preferences_receive_email] DEFAULT ((1)) NOT NULL,
    [last_update_on]            DATETIME     CONSTRAINT [DF_user_preferences_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]            INT          CONSTRAINT [DF_user_preferences_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_user_preferences] PRIMARY KEY CLUSTERED ([user_id] ASC)
);

