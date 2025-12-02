SELECT TOP (1000) [CommunicationId]
	,[Id]
	,Content.[ContentFieldId]
	,Item.ContentFieldDesc AS ContentField
	,Content.[ContentItemId]
	,Item.ContentItemDesc AS ContentItem
--,[Cost]
--,[IsControlForContent]
--,[UrnDefinitionId]
--,[Deleted]
--,Item.IsChannel
FROM [PS_DB01_Staging].[dbo].[FS_Build_Content] Content
LEFT OUTER JOIN (
	SELECT DISTINCT ContentFieldId
		,ContentFieldDesc
		,ContentItemId
		,ContentItemDesc
		,IsChannel
	FROM FS_Decode_Content
	WHERE ContentFieldId > 0
	) AS Item ON Content.ContentItemId = Item.ContentItemId
WHERE [CommunicationId] BETWEEN 235
		AND 238
	AND Item.IsChannel = 0
	AND Deleted IS NULL