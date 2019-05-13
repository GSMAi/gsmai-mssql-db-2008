CREATE TABLE [dbo].[test_links_ids] (
    [fk_group_data_id] BIGINT   NOT NULL,
    [fk_data_view_id]  INT      NOT NULL,
    [link_date]        DATETIME NOT NULL,
    [archive]          BIT      NOT NULL,
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [pk_test_links_ids] PRIMARY KEY CLUSTERED ([ID] ASC)
);

