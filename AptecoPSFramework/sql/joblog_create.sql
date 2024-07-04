-- sqlite
CREATE TABLE IF NOT EXISTS joblog (
     id              INTEGER PRIMARY KEY
    ,created         TEXT DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime'))
    ,updated         TEXT
    ,finished        INTEGER DEFAULT 0
    ,status          TEXT
    ,process         TEXT
    ,plugin          TEXT
    ,debug           INTEGER
    ,type            TEXT
    ,input           TEXT
    ,inputrecords    INTEGER
    ,successful      INTEGER
    ,failed          INTEGER
    ,totalseconds    INTEGER
    ,output          TEXT
);

CREATE TRIGGER IF NOT EXISTS update_joblog_trigger
AFTER UPDATE On joblog
BEGIN
   UPDATE joblog SET updated = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'localtime') WHERE id = NEW.id;
END;
