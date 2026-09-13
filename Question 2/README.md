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


