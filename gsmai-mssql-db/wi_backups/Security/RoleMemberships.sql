EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'wi';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'gsmai-femto';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'gsmaigeneric';


GO
EXECUTE sp_addrolemember @rolename = N'db_datawriter', @membername = N'gsmai-femto';

