
USE [PS_DB01]

SELECT Deliveries.CampaignId AS CampaignId
	,DeliveryCommands.DeliveryKey AS DeliveryKey
	,Deliveries.CampaignDesc AS Name
	,NULL AS Deactivated
	,NULL AS Deleted
	,DeliveryCommands.Run AS Run
	,DeliveryCommands.DateAdded AS TIMESTAMP
	,Deliveries.MessageId
	,Deliveries.MessageDesc
	,Deliveries.DeliveryStepId
	,DeliveryCommands.FilePath
	,SUBSTRING(DeliveryCommands.FilePath, LEN(DeliveryCommands.FilePath) - CHARINDEX('_', REVERSE(DeliveryCommands.FilePath)) + 2, CHARINDEX('_', REVERSE(DeliveryCommands.FilePath)) - CHARINDEX('.', REVERSE(DeliveryCommands.FilePath)) - 1) AS FileGUID
	,DeliveryCommands.AddCommKey
	,DeliveryCommands.CommKeyName
	,DeliveryCommands.UrnColumnName
	,DeliveryCommands.EmailColumnName
	,DeliveryCommands.Id
FROM (
	SELECT [Id]
		,[DateAdded]
		,coalesce([Command].value('(/DeliveryCommand/*/FileSpecification/AddCommunicationKey)[1]', 'nvarchar(50)'), 'false') AS AddCommKey
		,coalesce([Command].value('(/DeliveryCommand/*/FileSpecification/CommunicationKeyColumnName)[1]', 'nvarchar(50)'), NULL) AS CommKeyName
		,coalesce([Command].value('(/DeliveryCommand/*/UrnColumnName)[1]', 'nvarchar(50)'), NULL) AS UrnColumnName
		,coalesce([Command].value('(/DeliveryCommand/*/EmailColumnName)[1]', 'nvarchar(50)'), NULL) AS EmailColumnName
		,coalesce([Command].value('(/DeliveryCommand/*/ExternalId/IdType)[1]', 'nvarchar(50)'), NULL) AS ExternalIdType
		,coalesce([Command].value('(/DeliveryCommand/*/ExternalId/Id)[1]', 'nvarchar(50)'), NULL) AS ExternalId
		,coalesce([Command].value('(/DeliveryCommand/*/DeliveryKey)[1]', 'uniqueidentifier'), NULL) AS DeliveryKey
		,coalesce([Command].value('(/DeliveryCommand/*/Run)[1]', 'bigint'), NULL) AS Run
		,coalesce([Command].value('(/DeliveryCommand/*/FilePath)[1]', 'varchar(max)'), NULL) AS FilePath
		/*,[Command].value('(/DeliveryCommand/BroadcastActionDetails/StepId)[1]', 'bigint') AS StepId*/
		,[Status]
	FROM [faststats_schema].[vDeliveryCommands] /* sometimes dbo */
	WHERE [Command].value('(/DeliveryCommand/*/FilePath)[1]', 'varchar(max)') LIKE '%#FILE#'
		--OR [Command].value('(/DeliveryCommand/FtpActionDetails/FilePath)[1]', 'varchar(max)') LIKE '%#FILE#'
	) AS DeliveryCommands
INNER JOIN [dbo].[FS_Decode_Deliveries] AS Deliveries ON Deliveries.DeliveryStepId = DeliveryCommands.ExternalId

