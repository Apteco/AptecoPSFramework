COPY (
SELECT history.PartnerId, history.Kanal, history.Zeitpunkt, trim(split_part(delivery.Projektgruppe,'~',1)) as Projektgruppe, 'ORB'||LPAD(CAST(w.id AS VARCHAR), 6, '0') as Werbecode, delivery.Werbecode as WerbecodeKurzname
FROM read_csv('#TEMPDIR#\*.txt', delim = '\t', union_by_name = true, all_varchar = true, ESCAPE = '', encoding = 'utf-8', filename = true) delivery
LEFT OUTER JOIN read_csv('#HISTORY#', delim = '\t') history ON history.CommunicationKey = delivery.""Communication Key""
LEFT OUTER JOIN werbecodes w ON w.projektgruppe = trim(split_part(delivery.Projektgruppe,'~',1)) AND w.werbecode = delivery.Werbecode
WHERE delivery.Projektgruppe IS NOT NULL
	AND delivery.Werbecode IS NOT NULL
) TO '#EXPORTFILE#' (FORMAT csv, DELIMITER '\t', HEADER true, USE_TMP_FILE true)
-- TIMESTAMPFORMAT, QUOTE
;