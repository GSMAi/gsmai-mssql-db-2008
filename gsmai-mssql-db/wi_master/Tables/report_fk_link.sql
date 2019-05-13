CREATE TABLE [dbo].[report_fk_link] (
    [report_id] INT            NOT NULL,
    [fk]        NVARCHAR (128) NOT NULL,
    [fk_id]     INT            NOT NULL,
    [fk_2]      NVARCHAR (128) NULL,
    [fk_id_2]   INT            NULL,
    CONSTRAINT [PK_report_fk_link] PRIMARY KEY CLUSTERED ([report_id] ASC)
);

