import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;


// ---------------------------------------------------------------------------
// PostgreSQL configuration
//
// Values come from Config.toml.
// ---------------------------------------------------------------------------

configurable string dbHost = "localhost";
configurable int dbPort = 5432;

configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;


// ---------------------------------------------------------------------------
// Shared PostgreSQL client
//
// One client is reused throughout the lifetime of the RentalService.
// ---------------------------------------------------------------------------

final postgresql:Client db = check new (
    host = dbHost,
    username = dbUser,
    password = dbPassword,
    database = dbName,
    port = dbPort,
    connectionPool = {
        maxOpenConnections: 10
    }
);


