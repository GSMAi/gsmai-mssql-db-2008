CREATE TABLE [dbo].[surveys] (
    [id]   INT            IDENTITY (1, 1) NOT NULL,
    [name] NVARCHAR (512) NOT NULL,
    CONSTRAINT [PK_surveys] PRIMARY KEY CLUSTERED ([id] ASC)
);

