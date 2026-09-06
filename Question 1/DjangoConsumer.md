# Basic Structure : Built on Ubuntu Linux

                    ┌──────────────────────────┐
                    │        Web Browser       │
                    └─────────────┬────────────┘
                                  │ HTTP
                                  ▼
                    ┌──────────────────────────┐
                    │       Django :8000       │
                    │                          │
                    │ • Authentication         │
                    │ • Permissions            │
                    │ • HTML/UI                │
                    │ • Forms                  │
                    │ • Sessions               │
                    └─────────────┬────────────┘
                                  │ REST/JSON
                                  ▼
                    ┌──────────────────────────┐
                    │     Ballerina :8080      │
                    │                          │
                    │ • Library business rules │
                    │ • Loans / bookings       │
                    │ • Maintenance            │
                    │ • Asset management       │
                    └─────────────┬────────────┘
                                  │ SQL
                                  ▼
                    ┌──────────────────────────┐
                    │    PostgreSQL :5432      │
                    │                          │
                    │ • institutions           │
                    │ • sites                  │
                    │ • assets                 │
                    │ • components             │
                    │ • schedules              │
                    │ • work orders            │
                    │ • work tasks             │
                    └──────────────────────────┘



# Connections

1. Initial Login : 
```shell
sudo -u postgres psql
```

2. Create a dedicated user for the library service : 
```shell
CREATE USER library_service_user
WITH PASSWORD 'CHANGE_THIS_TO_A_LONG_RANDOM_PASSWORD';

CREATE DATABASE library_service_db
OWNER library_service_user;
```

