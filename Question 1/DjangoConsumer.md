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
WITH PASSWORD '123@Librarian!';

CREATE DATABASE library_service_db
OWNER library_service_user;

\q #To Quit the shell
```

3. Test the Access to db
```shell
psql -h 127.0.0.1 -U library_service_user -d library_service_db
```

4. Show tables
```shell
> \d
> \d[S+] 
```

## Database Schema for the service


library_service/
├── Ballerina.toml
├── Config.toml
├── schema.sql
├── seed.sql
├── service.bal
├── types.bal
├── database.bal
├── repository.bal
├── storage.bal
├── asset_handlers.bal
├── institution_handlers.bal
├── component_handlers.bal
├── loan_handlers.bal
├── schedule_handlers.bal
└── workorder_handlers.bal


1. Load the above Schema which is labelled as schema.sql
```shell
psql \
    -h 127.0.0.1 \
    -U library_service_user \
    -d library_service_db \
    -f schema.sql
```







