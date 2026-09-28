# Question 1 Django Consumer

The optional Django consumer follows this architecture:

```text
Browser
   |
   | HTTP
   v
Django :8000
   |
   | REST/JSON
   v
Ballerina library_service :8080
   |
   v
assetsTable + institutions map
```

Django handles pages and forms. It does not own library records. All library
data is stored inside the running Ballerina process:

- `table<Asset> key(assetTag) assetsTable`
- `map<Institution> institutions`

No PostgreSQL or other external data source is required. Restarting
`library_service` resets the data and reloads the sample records from
`data_init.bal`.

## Run

Start the Ballerina service:

```powershell
cd library_service
bal run
```

Then start Django from another terminal:

```powershell
cd djangoContainer
python manage.py runserver
```
