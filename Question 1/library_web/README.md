# Library Web Client - Learning Version

This folder contains an optional browser client for the Ballerina library service. It is designed as a teaching aid, not as a production system. The **How it works** page connects the working features to Week 3 concepts such as IPC, HTTP messages, JSON serialization, resource routes, and in-memory storage.

## Run locally

Start the backend first:

```powershell
cd ..\library_service
bal run
```

In another terminal, start this website:

```powershell
cd library_web
npm install
npm run dev
```

Open `http://localhost:3000` in a browser.

## How it communicates with Ballerina

The page calls routes beginning with `/api/library`. The proxy in `app/api/library/[...path]/route.ts` forwards each request to `http://127.0.0.1:8080/library`.

This avoids browser CORS problems and keeps the Ballerina URL in one place. To use a different backend URL, set the `LIBRARY_API_URL` environment variable before starting the website.

## Main files

- `app/page.tsx`: dashboard layout, asset tables, filters, forms, loaning, booking, and schedules
- `app/globals.css`: visual design and responsive mobile layout
- `app/api/library/[...path]/route.ts`: connection to the Ballerina API
- `app/layout.tsx`: page title and description

The original `library_client` folder is the main assignment client because Question 1 asks for Ballerina. Present this browser frontend only as an extra demonstration of another process communicating with the same service.

## A simple presentation order

1. Start on **How it works** and explain that the browser and service are separate processes.
2. Open **Assets** and explain that the page obtained the list with `GET /assets`.
3. Add one test asset and explain that the form becomes JSON in a `POST /assets` message.
4. Show `service.bal` and point to the resource function that receives the request.
5. Show `storage.bal` and explain why `assetTag` is the table key.
6. Restart the service and explain why the test asset disappears: the project uses in-memory storage.

## Questions to prepare for

- **Why is this IPC?** The client and service run as independent processes and pass messages through HTTP.
- **Why use a proxy?** The browser calls a same-origin web route, which forwards the request to Ballerina on port 8080 and avoids CORS problems.
- **Why use JSON?** It is the shared message representation understood by both TypeScript and Ballerina records.
- **Is the data permanent?** No. Restarting the Ballerina service reloads the sample data.
- **What prevents duplicate assets?** `assetsTable` uses `assetTag` as its unique key, and duplicate requests receive a conflict response.
