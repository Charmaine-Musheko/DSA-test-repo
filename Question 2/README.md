# Question 2 - Rental Platform

This project is a distributed rental application with a Ballerina gRPC
service and two clients:

```text
Browser -> Django :8000 -> gRPC -> Ballerina :9090 -> map/table storage
Terminal -> Ballerina CLI --------^
```

## Data source

The only application data source is `rental_service/storage.bal`. It defines
five keyed in-memory tables:

- `usersTable`, keyed by `userId`
- `propertiesTable`, keyed by `propertyId`
- `cartItemsTable`, keyed by `cartId`
- `bookingsTable`, keyed by `bookingId`
- `removedBookingsTable`, keyed by `bookingId`

No PostgreSQL connection, credentials, schema or SQL queries are required.
Data remains available while `rental_service` is running and resets when that
process restarts.

## Main functionality

- Create hosts and guests with client-side streaming
- Add, update, remove, search and list properties
- Filter available properties by location and price
- Create cart requests and confirm bookings
- Detect overlapping booking dates
- Calculate the number of nights and total cost
- Archive cancelled bookings in `removedBookingsTable`
- Stream users, properties and bookings back to clients

The shared `rental.proto` file is the contract for Ballerina, the CLI and
Django. Generated Protobuf source files should only be regenerated when that
contract changes.

See `SETUP.md` for commands.
