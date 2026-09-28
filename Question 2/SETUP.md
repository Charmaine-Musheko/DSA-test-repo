# Rental Platform Setup

## Prerequisites

- Ballerina 2201.13.5 or compatible
- Python 3
- Django
- `grpcio` and `protobuf`

PostgreSQL is not required.

## 1. Build and run the Ballerina service

```powershell
cd rental_service
bal build
bal run
```

The gRPC service listens on `localhost:9090`. Its records are stored in keyed
Ballerina tables in `storage.bal`.

## 2. Run the Ballerina CLI

Open another terminal:

```powershell
cd rental_client
bal build
bal run
```

The CLI calls the service through gRPC. It never accesses the service tables
directly.

## 3. Run Django

Install the Python packages if needed:

```powershell
python -m pip install django grpcio protobuf requests
```

Then start the web application:

```powershell
cd djangoContainer
python manage.py check
python manage.py runserver
```

Open `http://localhost:8000`.

Django calls `localhost:9090` through the generated Python gRPC client. The
rental records remain in Ballerina tables, not in Django models or SQLite.

## Runtime behavior

```text
Browser
   |
   v
Django
   |
   | gRPC / Protocol Buffers
   v
Ballerina RentalService
   |
   v
usersTable / propertiesTable / cartItemsTable /
bookingsTable / removedBookingsTable
```

Restarting Django does not clear the records because they live in the
Ballerina service. Restarting the Ballerina service creates new empty tables
and resets the ID counters.
