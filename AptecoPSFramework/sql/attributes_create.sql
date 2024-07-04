-- duckdb
CREATE SEQUENCE IF NOT EXISTS  attribute_id_sequence START 1;
CREATE TABLE IF NOT EXISTS attributes (
     id             INTEGER DEFAULT nextval('attribute_id_sequence')
    ,extid          VARCHAR
    ,name           VARCHAR
    ,description    VARCHAR
    ,scope          VARCHAR
    ,source         VARCHAR
    ,type           VARCHAR
    ,length         INTEGER
    ,category       VARCHAR
);