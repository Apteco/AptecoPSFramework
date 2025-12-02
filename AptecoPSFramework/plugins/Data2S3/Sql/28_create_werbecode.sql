
-- Create a sequence
CREATE SEQUENCE IF NOT EXISTS werbecode_sequence START 1;

-- Create table only if it doesn't exist
CREATE TABLE IF NOT EXISTS werbecodes (
    id INTEGER PRIMARY KEY DEFAULT nextval('werbecode_sequence'),
    projektgruppe VARCHAR,
    werbecode VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comment VARCHAR
);