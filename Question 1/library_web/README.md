# Ministry Library Web Client

This folder contains the modern browser client for the Ballerina library service.

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

The original `library_client` folder is kept because Question 1 specifically asks for a Ballerina client. This browser frontend can be demonstrated as the bonus web interface.
