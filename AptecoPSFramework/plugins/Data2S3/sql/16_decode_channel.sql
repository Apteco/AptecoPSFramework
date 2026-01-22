

SELECT DISTINCT ContentItemId AS Code
	,ContentItemDesc AS Description
FROM [PS_DB01_Staging].[dbo].[FS_Decode_Content]
WHERE IsChannel = 1

