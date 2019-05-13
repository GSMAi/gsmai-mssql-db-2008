CREATE TABLE [dbo].[cleaning] (
    [ds]                   VARCHAR (128)  NOT NULL,
    [ds_id]                BIGINT         NOT NULL,
    [cleaned_flags]        BIT            CONSTRAINT [DF_cleaning_cleaned_flags] DEFAULT ((0)) NOT NULL,
    [cleaned_source_files] BIT            CONSTRAINT [DF_cleaning_cleaned_location] DEFAULT ((0)) NOT NULL,
    [flags]                NVARCHAR (MAX) NULL,
    [source_files]         NVARCHAR (MAX) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_cleaning_ds]
    ON [dbo].[cleaning]([ds] ASC);

