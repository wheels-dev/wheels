-- Create test user and grant permissions
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER wheelstestdb IDENTIFIED BY "wheelstestdb123!";

GRANT CONNECT, RESOURCE TO wheelstestdb;
GRANT CREATE SESSION TO wheelstestdb;
GRANT CREATE TABLE TO wheelstestdb;
GRANT CREATE VIEW TO wheelstestdb;
GRANT CREATE PROCEDURE TO wheelstestdb;
GRANT CREATE SEQUENCE TO wheelstestdb;
GRANT CREATE TRIGGER TO wheelstestdb;
GRANT UNLIMITED TABLESPACE TO wheelstestdb;

-- Grant additional permissions for testing
GRANT SELECT ANY DICTIONARY TO wheelstestdb;
GRANT CREATE ANY INDEX TO wheelstestdb;
GRANT ALTER ANY TABLE TO wheelstestdb;
GRANT DROP ANY TABLE TO wheelstestdb;

COMMIT;