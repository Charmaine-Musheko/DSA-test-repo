# POSTGRESQL SETUP


1. Initial Login : 
```shell
sudo -u postgres psql
```


2. Create a dedicated user for the rental service : 
```shell
CREATE USER rental_service_user
WITH PASSWORD '123@Rental!';

CREATE DATABASE rental_service_db
OWNER rental_service_user;

\q #To Quit the shell
```

3. Test the Access to db
```shell
psql -h 127.0.0.1 -U rental_service_user -d rental_service_db
```

4. Load the above Schema which is labelled as schema.sql
```shell
psql \
    -h 127.0.0.1 \
    -U rental_service_user \
    -d rental_service_db \
    -f schema.sql
```

5. Show tables
```shell
123@Rental!
```

# Final Design

                   DISTRIBUTED SYSTEM

┌───────────────────────────────────────┐
│ Django rental_web                     │
│                                       │
│ rentalApp                             │
│ templates / views / forms             │
│                                       │
│ Django database:                      │
│ db.sqlite3                            │
└──────────────────┬────────────────────┘
                   │
                   │ gRPC / protobuf
                   │ localhost:9090
                   ▼
┌───────────────────────────────────────┐
│ Ballerina rental_service             │
│                                       │
│ Validation                            │
│ Business rules                        │
│ Booking collision detection           │
│ Price calculation                     │
│ Rental operations                     │
└──────────────────┬────────────────────┘
                   │
                   │ ballerinax/postgresql
                   ▼
┌───────────────────────────────────────┐
│ PostgreSQL                            │
│                                       │
│ rental_service_db                     │
│                                       │
│ users                                 │
│ properties                            │
│ cart_items                            │
│ bookings                              │
└───────────────────────────────────────┘


Separately:

┌───────────────────────────────────────┐
│ Ballerina rental_client CLI          │
└──────────────────┬────────────────────┘
                   │
                   │ gRPC
                   └──────────────► rental_service

## Proto Usage

                         rental.proto
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
  rental_service        rental_client       Django rentalApp
     Ballerina             Ballerina             Python
          │
          │ PostgreSQL
          ▼
 rental_service_db
          │
          └── rental schema

## Django Views

Users
 ├── Create users
 ├── View all users
 ├── View hosts only
 ├── View guests only
 └── Search user

Properties
 ├── Add property
 ├── List/filter available properties
 ├── Search property
 ├── Update property
 └── Remove property

Bookings
 ├── Add to cart
 ├── Confirm booking
 ├── View active bookings
 ├── Search active/removed booking
 ├── Remove/archive booking
 └── View removed booking history