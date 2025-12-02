
INSERT INTO werbecodes BY NAME (
SELECT d.* FROM (
SELECT DISTINCT trim(split_part(Projektgruppe,'~',1)) as projektgruppe, werbecode
FROM read_csv('#TEMPDIR#\*.txt', delim = '\t', union_by_name = true, all_varchar = true, ESCAPE = '', encoding = 'utf-8', filename = true) delivery
WHERE Projektgruppe IS NOT NULL
	AND Werbecode IS NOT NULL
) d
LEFT OUTER JOIN werbecodes as w ON w.projektgruppe = d.projektgruppe AND w.werbecode = d.werbecode
WHERE w.id is null
);