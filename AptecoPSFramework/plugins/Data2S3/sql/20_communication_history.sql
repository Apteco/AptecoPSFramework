USE [PS_DB01_Staging]

SELECT [Id] AS CommunicationId
	--,[Urn]
	--,[StepId]
	--,[StateId]
	--,[TreatmentOutputId]
	,[CommunicationTime] as Zeitpunkt
	--,[Run]
	,[ChannelId]
	,channels.Description AS Kanal
	--,[IsControlForDelivery] AS Kontrollgruppe
	--,[CompoundKeycode]
	--,[BatchSetId]
	--,[MessageId]
	--,[CampaignId]
	,[CommunicationKey]
	--,[UrnDefinitionId]
	,[AgentUrn] AS PartnerId
    ,'#FILEGUID#' as FileGuid
--,[DeliveryGroupId]
--,[Deleted]
FROM [PS_DB01_Staging].[dbo].[Communications] comms
LEFT OUTER JOIN (
	SELECT DISTINCT ContentItemId AS Code
		,ContentItemDesc AS Description
	FROM [PS_DB01_Staging].[dbo].[FS_Decode_Content]
	WHERE IsChannel = 1
	) channels ON channels.Code = comms.ChannelId
WHERE [Deleted] IS NULL
    AND comms.IsControlForDelivery = 0
    AND comms.CampaignId = #CAMPAIGN#
    AND comms.Run = #RUN#
    AND comms.StepId = #STEP#
	--AND [Id] BETWEEN 235 AND 238