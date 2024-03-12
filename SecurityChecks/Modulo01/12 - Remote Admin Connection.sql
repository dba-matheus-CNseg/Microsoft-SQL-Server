
-- Verificando se a configura��o est� habilitada
EXEC sp_configure 'remote admin connections', 0
RECONFIGURE

SELECT * FROM sys.configurations WHERE [name] = 'remote admin connections'
SELECT * FROM sys.endpoints



-- Habilitando a conex�o DAC
EXEC sp_configure 'remote admin connections', 1
GO

RECONFIGURE
GO


-- Identificar quem est� utilizando a conex�o DAC
SELECT
    B.session_id,
    A.[name],
    B.connect_time,
    B.last_read,
    B.last_write,
    B.client_net_address
FROM
    sys.endpoints A
    JOIN sys.dm_exec_connections B ON A.endpoint_id = B.endpoint_id
WHERE
    A.is_admin_endpoint = 1


-- Criar uma trigger para impedir logins
USE [master]
GO

IF ((SELECT COUNT(*) FROM sys.server_triggers WHERE name = 'trgAudit_Login') > 0) DROP TRIGGER [trgAudit_Login] ON ALL SERVER
GO

CREATE OR ALTER TRIGGER [trgAudit_Login] ON ALL SERVER 
FOR LOGON 
AS
BEGIN


    SET NOCOUNT ON
    
    
    -- N�o loga conex�es de usu�rios de sistema
    IF (ORIGINAL_LOGIN() IN ('sa', 'AUTORIDADE NT\SISTEMA', 'NT AUTHORITY\SYSTEM') OR ORIGINAL_LOGIN() LIKE '%SQLServerAgent')
        RETURN
        

    PRINT 'Usu�rio n�o permitido para logar neste servidor. Favor entrar em contato com a equipe de Banco de Dados'
    ROLLBACK


END
GO

ENABLE TRIGGER [trgAudit_Login] ON ALL SERVER  
GO



-- Conectado via DAC, Desativa a trigger
DISABLE TRIGGER [trgAudit_Login] ON ALL SERVER  
GO


-- Altera a quantidade m�xima de usu�rios para 1
sp_configure N'show advanced options', N'1'
GO

RECONFIGURE
GO

sp_configure N'user connections', 0

SELECT * FROM sys.configurations WHERE name = 'user connections'

RECONFIGURE
GO


-- Conectado utilizando a DAC, volto a configura��o para o valor correto
sp_configure N'show advanced options', N'1'
GO

RECONFIGURE
GO

sp_configure N'user connections', 0

RECONFIGURE
GO