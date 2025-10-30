

SELECT c.*, lower(trim(strip_accents(c.name))) as normalised_name
FROM attributes c
WHERE c.source = 'csv'
	AND ( c.category NOT IN ('email', 'urn') OR c.category IS NULL )
	AND lower(trim(strip_accents(c.name))) NOT IN (
		SELECT lower(trim(strip_accents(name)))
		FROM attributes
		WHERE source = 'api'
		);

