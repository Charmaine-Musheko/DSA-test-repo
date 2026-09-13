# Rental Platform — Setup and Running Guide

## 1. Project Overview

This project implements a distributed rental platform using:

```text
Django Web Application
        │
        │ gRPC
        ▼
Ballerina Rental Service
        │
        │ SQL
        ▼
PostgreSQL
```

A separate Ballerina CLI client can also communicate with the same rental service:

```text
Ballerina CLI Client
        │
        │ gRPC
        ▼
Ballerina Rental Service
        │
        │ SQL
        ▼
PostgreSQL
```

The architecture intentionally separates the presentation/client layers from the persistent database.

Django does **not** connect directly to PostgreSQL.

The Ballerina CLI client does **not** connect directly to PostgreSQL.

Only the Ballerina `rental_service` communicates with the PostgreSQL rental database.

Django may retain its normal local SQLite database for Django-specific functionality.

---

# 2. Project Structure

The project is expected to have approximately the following structure:

```text
Question 2/
│
├── README.md
│
├── djangoContainer/
│   ├── db.sqlite3
│   ├── manage.py
│   ├── Pipfile
│   ├── Pipfile.lock
│   │
│   ├── rentalApp/
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── grpc_client.py
│   │   ├── models.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   ├── views.py
│   │   │
│   │   └── grpc_generated/
│   │       ├── __init__.py
│   │       ├── rental_pb2.py
│   │       └── rental_pb2_grpc.py
│   │
│   ├── RentalProject/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── asgi.py
│   │   └── wsgi.py
│   │
│   └── templates/
│       ├── base.html
│       │
│       └── rentalApp/
│           ├── dashboard.html
│           ├── create_users.html
│           ├── user_list.html
│           ├── search_user.html
│           ├── property_list.html
│           ├── add_property.html
│           ├── search_property.html
│           ├── update_property.html
│           ├── remove_property.html
│           ├── book_property.html
│           ├── confirm_booking.html
│           ├── booking_list.html
│           ├── search_booking.html
│           ├── remove_booking.html
│           └── removed_booking_list.html
│
├── rental_service/
│   ├── Ballerina.toml
│   ├── Dependencies.toml
│   ├── Config.toml
│   ├── database.bal
│   ├── storage.bal
│   ├── types.bal
│   ├── rental_handlers.bal
│   ├── rentalservice_service.bal
│   ├── rental_pb.bal
│   ├── schema.sql
│   │
│   └── proto/
│       └── rental.proto
│
└── rental_client/
    ├── Ballerina.toml
    ├── Dependencies.toml
    ├── rentalservice_client.bal
    ├── rental_pb.bal
    │
    └── proto/
        └── rental.proto
```

---

# 3. Main Architecture

The main communication flow is:

```text
Browser
   │
   ▼
Django
   │
   │ gRPC
   ▼
Ballerina rental_service :9090
   │
   │ PostgreSQL connector
   ▼
rental_service_db
```

The CLI follows:

```text
Terminal
   │
   ▼
Ballerina rental_client
   │
   │ gRPC
   ▼
Ballerina rental_service :9090
   │
   ▼
PostgreSQL
```

The database is therefore centralized behind the Ballerina service.

---

# 4. Prerequisites

The development environment used for this project is Ubuntu 22.04.

The following software should be installed:

```text
Ballerina
PostgreSQL
Python 3
pip
Pipenv
Git
```

Verify Python:

```bash
python3 --version
```

Verify Pipenv:

```bash
pipenv --version
```

Verify PostgreSQL:

```bash
psql --version
```

Verify Ballerina:

```bash
bal version
```

---

# 5. Navigate to the Project

The project location used during development is:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2"
```

Verify the directories:

```bash
ls
```

Expected:

```text
README.md
djangoContainer
rental_client
rental_service
```

---

# 6. Install PostgreSQL

If PostgreSQL is not already installed:

```bash
sudo apt update
```

```bash
sudo apt install postgresql postgresql-contrib
```

Start PostgreSQL:

```bash
sudo systemctl enable postgresql
```

```bash
sudo systemctl start postgresql
```

Check its status:

```bash
sudo systemctl status postgresql
```

---

# 7. Create the Rental Database

Open PostgreSQL as the administrative user:

```bash
sudo -u postgres psql
```

Create the rental database user:

```sql
CREATE USER rental_service_user
WITH PASSWORD '123@Rental!';
```

Create the database:

```sql
CREATE DATABASE rental_service_db
OWNER rental_service_user;
```

Connect to the database:

```sql
\c rental_service_db
```

Allow the service user to connect and create objects:

```sql
GRANT CONNECT, CREATE
ON DATABASE rental_service_db
TO rental_service_user;
```

Create a dedicated schema:

```sql
CREATE SCHEMA IF NOT EXISTS rental
AUTHORIZATION rental_service_user;
```

Grant schema privileges:

```sql
GRANT USAGE, CREATE
ON SCHEMA rental
TO rental_service_user;
```

Configure the default search path:

```sql
ALTER ROLE rental_service_user
IN DATABASE rental_service_db
SET search_path = rental, public;
```

Exit PostgreSQL:

```sql
\q
```

---

# 8. Test the PostgreSQL Login

Connect using the service account:

```bash
psql \
    -h 127.0.0.1 \
    -U rental_service_user \
    -d rental_service_db
```

Enter:

```text
123@Rental!
```

Check the search path:

```sql
SHOW search_path;
```

Expected:

```text
rental, public
```

Check the active schema:

```sql
SELECT current_schema();
```

Expected:

```text
rental
```

Exit:

```sql
\q
```

---

# 9. Create the Database Tables

Navigate to the service:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2/rental_service"
```

The `schema.sql` file should begin with:

```sql
SET search_path TO rental, public;
```

Run the schema:

```bash
psql \
    -h 127.0.0.1 \
    -U rental_service_user \
    -d rental_service_db \
    -f schema.sql
```

Enter the password:

```text
123@Rental!
```

Verify the tables:

```bash
psql \
    -h 127.0.0.1 \
    -U rental_service_user \
    -d rental_service_db
```

Then:

```sql
\dt rental.*
```

Expected tables include:

```text
users
properties
cart_items
bookings
removed_bookings
```

Test them:

```sql
SELECT COUNT(*) FROM rental.users;
```

```sql
SELECT COUNT(*) FROM rental.properties;
```

```sql
SELECT COUNT(*) FROM rental.cart_items;
```

```sql
SELECT COUNT(*) FROM rental.bookings;
```

```sql
SELECT COUNT(*) FROM rental.removed_bookings;
```

A new database should normally return:

```text
0
```

for each table.

Exit:

```sql
\q
```

---

# 10. Configure the Ballerina Rental Service

Navigate to:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2/rental_service"
```

Create or verify `Config.toml`:

```toml
dbHost = "localhost"
dbPort = 5432
dbUser = "rental_service_user"
dbPassword = "123@Rental!"
dbName = "rental_service_db"
```

The Ballerina database connection is defined in `database.bal`.

The approximate architecture is:

```text
rentalservice_service.bal
        │
        ▼
rental_handlers.bal
        │
        ▼
storage.bal
        │
        ▼
database.bal
        │
        ▼
PostgreSQL
```

`database.bal` is responsible only for creating the PostgreSQL client.

`storage.bal` contains SQL queries.

`rental_handlers.bal` contains business logic.

`rentalservice_service.bal` exposes the gRPC API.

---

# 11. Protect Database Credentials

The `Config.toml` file should not be committed to Git.

At the Question 2 repository level, `.gitignore` should contain:

```gitignore
target/
**/target/

**/Config.toml

__pycache__/
*.pyc
```

---

# 12. Protocol Buffer Source of Truth

The main protocol definition is:

```text
rental_service/proto/rental.proto
```

This should be treated as the source of truth.

The same protocol is used to generate code for:

```text
Ballerina rental_service
Ballerina rental_client
Django Python gRPC client
```

Conceptually:

```text
                       rental.proto
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
      rental_service   rental_client     Django
      rental_pb.bal    rental_pb.bal    rental_pb2.py
                                      rental_pb2_grpc.py
```

Do not manually edit generated protobuf code.

---

# 13. When to Regenerate `rental_pb.bal`

Regenerate protobuf-generated files only when `rental.proto` changes.

If only normal Ballerina application logic changes, regeneration is unnecessary.

Examples of changes that require regeneration include:

```text
Adding a new RPC
Removing an RPC
Adding a message
Changing a message field
Changing an enum
Changing client/server streaming behaviour
```

---

# 14. Generate the Ballerina Service Stub

Navigate to:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2/rental_service"
```

Remove the old generated file if regenerating:

```bash
rm -f rental_pb.bal
```

Generate it:

```bash
bal grpc \
    --input proto/rental.proto \
    --proto-path proto \
    --output .
```

Verify the generated file:

```bash
ls rental_pb.bal
```

---

# 15. Build the Ballerina Service

From `rental_service`:

```bash
bal clean
```

Then:

```bash
bal build
```

The build should complete without compiler errors.

---

# 16. Run the Ballerina Service

Start the service:

```bash
bal run
```

The service listens on:

```text
localhost:9090
```

Leave this terminal running.

This is **Terminal 1**.

---

# 17. Verify Port 9090

Open another terminal and run:

```bash
nc -vz 127.0.0.1 9090
```

Expected:

```text
Connection to 127.0.0.1 9090 port [tcp/*] succeeded!
```

If necessary, inspect the process:

```bash
sudo lsof -nP -iTCP:9090 -sTCP:LISTEN
```

There should normally be only one rental service listening on the port.

If an old process is stuck on the port:

```bash
sudo fuser -k 9090/tcp
```

Then restart:

```bash
bal run
```

---

# 18. Set Up the Ballerina CLI Client

Open **Terminal 2**.

Navigate to:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2/rental_client"
```

The CLI does not connect directly to PostgreSQL.

Its communication path is:

```text
rental_client
      │
      │ gRPC
      ▼
rental_service
      │
      ▼
PostgreSQL
```

---

# 19. Synchronize the Client Proto

When `rental.proto` changes, copy the latest service proto:

```bash
cp \
    ../rental_service/proto/rental.proto \
    proto/rental.proto
```

Remove the old generated client file:

```bash
rm -f rental_pb.bal
```

Regenerate:

```bash
bal grpc \
    --input proto/rental.proto \
    --proto-path proto \
    --output .
```

---

# 20. Build the Ballerina CLI Client

Run:

```bash
bal clean
```

Then:

```bash
bal build
```

If the build succeeds, run:

```bash
bal run
```

The CLI should display a menu similar to:

```text
1.  Create users
2.  Add property
3.  List available properties
4.  Search property
5.  Update property
6.  Book property
7.  Confirm booking
8.  Remove property
9.  Run complete end-to-end demonstration
10. Inspect CLI convenience state
11. View users
12. Search user
13. View active bookings
14. Search booking
15. Remove / cancel booking
16. View removed booking history
0.  Exit
```

The CLI uses server-generated IDs.

Examples:

```text
USR-0001
PROP-0001
CART-0001
BKG-0001
```

The client should not generate these IDs itself.

---

# 21. Verify CLI Persistence

Create users through the CLI.

For example:

```text
Host:
Name: Katrina Host
Email: kat@example.na
Role: HOST
Region: Erongo
```

Then create a guest.

Exit the CLI.

Restart it:

```bash
bal run
```

Choose:

```text
11. View users
```

The previously created users should still be returned.

This demonstrates that the records are persisted in PostgreSQL and are not simply stored in the CLI process.

---

# 22. Set Up Django

Open **Terminal 3**.

Navigate to:

```bash
cd "/home/phoenix/Documents/NUST/Distributed Systems/DSA-Test-Repo/DSA-test-repo/Question 2/djangoContainer"
```

---

# 23. Activate the Pipenv Environment

Run:

```bash
pipenv shell
```

The shell should change to something similar to:

```text
(djangoContainer)
```

---

# 24. Install Required Python Packages

Install Django if necessary:

```bash
pipenv install django
```

Install gRPC:

```bash
pipenv install grpcio grpcio-tools protobuf
```

Verify:

```bash
pipenv graph
```

---

# 25. Keep Django on SQLite

Django itself should retain the normal SQLite configuration.

In:

```text
RentalProject/settings.py
```

use:

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

Do **not** configure Django to connect directly to:

```text
rental_service_db
```

The correct architecture is:

```text
Django
   │
   │ gRPC
   ▼
Ballerina
   │
   ▼
PostgreSQL
```

not:

```text
Django ───────► PostgreSQL
```

---

# 26. Configure Django Templates

In:

```text
RentalProject/settings.py
```

ensure:

```python
"DIRS": [BASE_DIR / "templates"],
```

is configured inside `TEMPLATES`.

For example:

```python
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",

        "DIRS": [
            BASE_DIR / "templates",
        ],

        "APP_DIRS": True,

        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]
```

---

# 27. Generate the Python gRPC Files

From:

```text
djangoContainer/
```

create the generated module directory if necessary:

```bash
mkdir -p rentalApp/grpc_generated
```

Create its package file:

```bash
touch rentalApp/grpc_generated/__init__.py
```

Remove old generated protobuf files if regenerating:

```bash
rm -f \
    rentalApp/grpc_generated/rental_pb2.py \
    rentalApp/grpc_generated/rental_pb2_grpc.py
```

Generate from the **same Ballerina service proto**:

```bash
python -m grpc_tools.protoc \
    -I ../rental_service/proto \
    --python_out=rentalApp/grpc_generated \
    --grpc_python_out=rentalApp/grpc_generated \
    ../rental_service/proto/rental.proto
```

---

# 28. Fix the Generated Python Import

The gen
