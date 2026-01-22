

SELECT r.[Id] AS ResponseId
	,r.[Email]
	,r.[Urn]
	,r.[MessageType]
	,r.[MessageName]
	,r.[DeliveryDate]
	,r.[ClickUrl]
	,r.[ClickDate]
	,r.[EventTriggeredDate]
	,r.[BroadcastId]
	,b.ListName
	,b.StepId
	,b.Run
	,c.AgentUrn
	,c.MessageId
	,c.CampaignId
	,c.ChannelId
	,rd.*
FROM [RS_DB01].[dbo].[Response] r
LEFT OUTER JOIN [RS_DB01].[dbo].[Broadcasts] b ON r.BroadcastId = b.Id
LEFT OUTER JOIN [PS_DB01_Staging].[dbo].[Communications] c ON c.StepId = b.StepId
	AND c.Run = b.Run
	AND CAST(r.Urn AS NVARCHAR(255)) = CAST(c.Urn AS NVARCHAR(255))
LEFT OUTER JOIN (
	SELECT *
	FROM [RS_DB01].[dbo].[ResponseDetails] r
	PIVOT(MAX(Value) FOR Name IN (
				BounceRelatedTo
				,BounceContactBlocked
				,BounceReason
				,Platform
				,SpamassassinScore
				,BounceClass
				,Geo
				,SpamassRules
				,BlockRelatedTo
				,BlockReason
				,Ip
				,IsMobile
				,UserAgent
				,Browser
				,Import
				,Broadcaster
				,IsBot
				)) AS p
	) AS rd ON r.Id = rd.Id
WHERE --EventTriggeredDate between '2025-12-12 00:00:00' and '2025-12-12 23:59:59'
	CAST(EventTriggeredDate AS DATE) = '#DATE#';

