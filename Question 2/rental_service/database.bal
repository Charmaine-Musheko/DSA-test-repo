import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

// ============================================================================
// DATABASE CONFIGURATION
// ============================================================================
//
// These values come from Config.toml.
//
// Only the Ballerina rental_service connects to PostgreSQL.
//
// Django continues using its own SQLite db.sqlite3.
// ============================================================================

configurable string dbHost = "localhost";
configurable int dbPort = 5432;

configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;


// ============================================================================
// SHARED POSTGRESQL CLIENT
// ============================================================================
//
// A single PostgreSQL client is reused by all repository functions in
// storage.bal.
// ============================================================================

final postgresql:Client db = check new (
    host = dbHost,
    port = dbPort,
    username = dbUser,
    password = dbPassword,
    database = dbName
);