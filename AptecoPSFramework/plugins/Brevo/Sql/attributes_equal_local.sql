

SELECT a.*
	,c.id AS c_id
	,c.extid AS c_exid
	,c.name AS c_name
	,c.description AS c_description
	,c.source AS c_source
	,c.type AS c_type
	,c.length AS c_type
	,c.category AS c_category
	, lower(trim(strip_accents(a.name))) as normalised_name
FROM attributes c
JOIN attributes a ON (lower(trim(strip_accents(a.name))) = lower(trim(strip_accents(c.name))))
WHERE c.source = 'csv'
	AND a.source = 'api'
	AND a.scope = 'local'
	AND ( c.category not in ('urn','email','commkey') OR c.category IS NULL )

