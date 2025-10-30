

SELECT a.*, lower(trim(strip_accents(a.name))) as normalised_name
FROM attributes a
WHERE a.source = 'api'
	AND lower(trim(strip_accents(a.name))) NOT IN (
		SELECT lower(trim(strip_accents(name)))
		FROM attributes
		WHERE source = 'csv'
		);

