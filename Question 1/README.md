# Question 1 - Library and Resource Management System

This is a simple Ballerina solution for Question 1 of the DSA612S assignment. It has three separate programs:

- `library_service`: the REST API and in-memory data storage
- `library_client`: the command-line program used to call the API
- `library_web`: a modern browser interface that uses the same REST API

The code is split into small files so that each part can be understood and retyped separately.

## How the solution matches the question

| Assignment requirement | Main file(s) |
| --- | --- |
| Asset CRUD and global view | `asset_handlers.bal`, `service.bal` |
| Filter by institution and campus | `asset_handlers.bal` |
| Check status and overdue schedules | `asset_handlers.bal`, `storage.bal` |
| Add/remove components | `component_handlers.bal` |
| Add/update/remove schedules | `schedule_handlers.bal` |
| Open/update/close work orders and tasks | `workorder_handlers.bal` |
| Add/remove institutions and sites | `institution_handlers.bal` |
| Table with `assetTag` as unique key | `storage.bal` |
| Loaning, booking, views, and schedules | files in `library_client` |

## Run the programs

Open two terminals. Start the service first:

```powershell
cd library_service
bal run
```

Then start the client in the second terminal:

```powershell
cd library_client
bal run
```

The service runs at `http://localhost:8080/library`. The client displays a numbered menu, so no HTTP commands have to be typed manually.

For the browser interface, open another terminal:

```powershell
cd library_web
npm install
npm run dev
```

Open `http://localhost:3000`. Keep `library_service` running because the website gets all its data from the Ballerina API.

## A good order for manually recoding it

1. Create `library_service/Ballerina.toml` and `library_client/Ballerina.toml`.
2. Retype `types.bal` first. These records describe the JSON data.
3. Retype `storage.bal`. Notice that `table<Asset> key(assetTag)` makes the asset tag unique.
4. Retype `data_init.bal` to add a few example institutions and assets.
5. Retype the handler files one at a time. Each handler reads or changes the table.
6. Retype `service.bal` last. Its resource functions connect HTTP routes to the handlers.
7. For the client, start with `main.bal` and `http_helpers.bal`, then add one menu file at a time.
8. Run `bal build` in each project after every few files. Fix errors before continuing.

## Main REST routes

| Method | Route | Purpose |
| --- | --- | --- |
| GET / POST | `/library/assets` | List or create assets |
| GET / PUT / DELETE | `/library/assets/{assetTag}` | Read, update, or delete one asset |
| GET | `/library/assets/institution/{name}` | Filter by institution |
| GET | `/library/assets/institution/{name}/site/{site}` | Filter by institution and site |
| GET | `/library/assets/overdue` | Show assets with overdue schedules |
| GET | `/library/assets/{assetTag}/status` | Show status and overdue value |
| POST | `/library/assets/{assetTag}/loan` | Loan an available asset |
| POST | `/library/assets/{assetTag}/book` | Book an available room or lab |
| GET / POST | `/library/assets/{assetTag}/components` | View or add components |
| GET / POST | `/library/assets/{assetTag}/schedules` | View or add schedules |
| GET / POST | `/library/assets/{assetTag}/workorders` | View or add work orders |
| GET / POST | `/library/institutions` | View or add institutions |

The remaining `PUT` and `DELETE` routes for schedules, work orders, tasks, institutions, and sites can be seen clearly in `library_service/service.bal`.

## What to understand for the presentation

- A Ballerina `record` becomes the shape of a JSON request or response.
- The `assetsTable` stores data only while the service is running. Restarting the service reloads the sample data.
- `assetTag` is the table key, so two assets cannot use the same tag.
- Resource functions define the HTTP method and route. Handler functions contain the actual logic.
- Successful requests return 2xx responses. Invalid input, missing records, and duplicates return 400, 404, or 409 responses.
- An asset is overdue when it has a `PENDING` schedule whose `dueDate` is before today's date.

Retype the code in your own working branch, test each menu option, and make sure every group member can explain the part they contributed.
