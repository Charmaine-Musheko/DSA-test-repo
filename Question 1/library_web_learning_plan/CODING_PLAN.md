# Coding Plan: Rebuild the Ministry Library Web Client

This plan explains how to rebuild the working `library_web` project yourself. Do not copy the complete page at once. Complete one phase, run it, and only continue when that phase works.

Use `COMMANDS.md` for the exact PowerShell commands needed to create, run, build, and test the project.

## 1. Understand the architecture

The project has three separate parts:

```text
Browser
   |
   | fetch('/api/library/assets')
   v
Web proxy in library_web
   |
   | forwards the HTTP request
   v
Ballerina service on port 8080
   |
   v
assetsTable and institutions map
```

The web project does not store permanent asset data. It displays and changes the data held by the Ballerina server.

## 2. Create the web project

Create a frontend folder next to `library_service`:

```text
Question 1/
├── library_service/
├── library_client/
└── your_library_web/
```

Use a React/Next-compatible project with these important files:

```text
your_library_web/
├── app/
│   ├── api/library/[...path]/route.ts
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── package.json
└── README.md
```

Checkpoint: Run the empty website and confirm that it opens in the browser.

## 3. Add the page layout

Start with only static HTML/JSX. Do not connect the API yet.

Build these areas in `app/page.tsx`:

1. `app-shell`: wraps the entire application.
2. `sidebar`: contains the name and navigation buttons.
3. `workspace`: contains the selected page.
4. `topbar`: page heading, refresh button, and Add Asset button.
5. `page-content`: the content below the top bar.

Use four navigation choices:

```ts
type View = "overview" | "assets" | "schedules" | "institutions";
```

Create state to remember the current view:

```ts
const [view, setView] = useState<View>("overview");
```

Checkpoint: Every sidebar button should change the heading and displayed section.

## 4. Define the TypeScript data models

Create TypeScript types near the top of `page.tsx`. They must match the Ballerina records in `library_service/types.bal`.

Define:

- `AssetStatus`
- `ComponentPart`
- `Schedule`
- `WorkOrder`
- `Asset`
- `Institution`

The main type should have this shape:

```ts
type Asset = {
  assetTag: string;
  name: string;
  description: string;
  institution: string;
  site: string;
  dateAcquired: string;
  status: AssetStatus;
  components: ComponentPart[];
  schedules: Schedule[];
  workOrders: WorkOrder[];
};
```

Checkpoint: TypeScript should compile without using `any` for asset data.

## 5. Build the API proxy

Browsers normally block calls between different origins. The website runs on port 3000 and Ballerina runs on port 8080, so the proxy keeps browser requests on the same origin.

Create `app/api/library/[...path]/route.ts`.

The proxy must:

1. Read the remaining route segments from `path`.
2. Add them to `http://127.0.0.1:8080/library`.
3. forward the HTTP method and JSON request body.
4. Return the Ballerina status code and response body.
5. Return status 503 when the Ballerina server is unavailable.

Export the same forwarding function for:

```ts
export const GET = forward;
export const POST = forward;
export const PUT = forward;
export const DELETE = forward;
```

Checkpoint: Opening `/api/library/assets` in the browser should display the JSON asset array.

## 6. Create a reusable API function

In `page.tsx`, create one function for all frontend requests:

```ts
async function api<T>(path: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`/api/library${path}`, options);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || "Request failed");
  }

  return data as T;
}
```

Improve it by automatically setting `Content-Type: application/json` when a request has a body.

Checkpoint: Use `api<Asset[]>("/assets")` and print the returned array in the browser console.

## 7. Load the backend data

Create state for assets, institutions, loading, and errors:

```ts
const [assets, setAssets] = useState<Asset[]>([]);
const [institutions, setInstitutions] = useState<Institution[]>([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState("");
```

Create a `loadData` function that requests both lists with `Promise.all`:

```ts
const [assetData, institutionData] = await Promise.all([
  api<Asset[]>("/assets"),
  api<Institution[]>("/institutions")
]);
```

Call `loadData()` inside `useEffect` when the page opens.

Display:

- A loading state while waiting.
- An error banner if the server cannot be reached.
- The dashboard when data is ready.

Checkpoint: Stop Ballerina and confirm that the website displays a helpful error. Restart Ballerina and confirm that Refresh works.

## 8. Build the overview dashboard

Create an `Overview` component.

Calculate:

- Total number of assets.
- Assets with status `AVAILABLE`.
- Assets with status `LOANED_OUT` or `OCCUPIED`.
- Assets containing overdue schedules.

An overdue schedule is:

```ts
schedule.status === "PENDING" &&
schedule.dueDate < new Date().toISOString().slice(0, 10)
```

Add:

- Welcome banner.
- Four statistics cards.
- Recent-assets list.
- Overdue-items list.

Checkpoint: Compare the dashboard numbers with `GET /library/assets`.

## 9. Build the asset catalogue

Create an `AssetsView` component.

Add two state values:

```ts
const [search, setSearch] = useState("");
const [institutionFilter, setInstitutionFilter] = useState("ALL");
```

Use `filter()` to match:

- Asset name.
- Asset tag.
- Institution.
- Site/campus.

Render a table containing:

- Asset name and tag.
- Institution and site.
- Date acquired.
- Status.
- Loan and Book buttons for available assets.
- A details button.

Checkpoint: Search for `NUST`, then filter by University of Namibia.

## 10. Create reusable visual components

Create small components instead of repeating markup:

- `StatusPill`: converts `AVAILABLE` into a green status label.
- `AssetGlyph`: gives each asset a simple letter icon.
- `StatCard`: displays one dashboard number.
- `Modal`: common popup layout.
- `FormActions`: Cancel and Save buttons.
- `Detail`: label/value pair in the asset drawer.

Checkpoint: Change one `StatusPill` style and confirm that it updates everywhere.

## 11. Create the asset details drawer

Store the selected asset:

```ts
const [selectedAsset, setSelectedAsset] = useState<Asset | null>(null);
```

When a row is clicked, set the selected asset. Display a drawer containing:

- Full asset description.
- Institution and campus.
- Date acquired and tag.
- Schedules.
- Component count.
- Open work-order count.
- Loan, Book, Add Schedule, and Delete buttons.

Checkpoint: Open three different assets and confirm that the drawer information changes.

## 12. Build the Add Asset form

Create an `AssetForm` modal.

Collect:

- Asset tag.
- Name.
- Description.
- Institution.
- Site/campus.
- Date acquired.
- Starting status.

When the institution changes, use its `sites` array to update the site options.

Construct the payload from `FormData` and send:

```ts
await api("/assets", {
  method: "POST",
  body: JSON.stringify(payload)
});
```

After success:

1. Close the modal.
2. Show a success message.
3. Call `loadData()` again.

Checkpoint: Add an asset, refresh the page, and confirm that it remains until the Ballerina service restarts.

## 13. Add loaning and booking

Create one `ActivityForm` that accepts either `loan` or `book` mode.

Loan payload:

```ts
{
  borrower: "Student Name",
  dueDate: "2026-09-10",
  description: "Research loan"
}
```

Booking payload:

```ts
{
  bookedBy: "Student Name",
  dueDate: "2026-09-10",
  description: "Group meeting"
}
```

Send to `/assets/{assetTag}/loan` or `/assets/{assetTag}/book`.

Checkpoint: After a loan, confirm that the asset status becomes `LOANED_OUT` and its Loan button disappears.

## 14. Build the schedule manager

Flatten the schedules from every asset:

```ts
const allSchedules = assets.flatMap((asset) =>
  asset.schedules.map((schedule) => ({ asset, schedule }))
);
```

Display each schedule with:

- Due date.
- Type.
- Asset name and tag.
- Description.
- Pending/completed status.
- Overdue label.

Create an Add Schedule form and POST it to:

```text
/assets/{assetTag}/schedules
```

Checkpoint: Add a maintenance schedule and confirm that it appears immediately.

## 15. Build the institution view

For every institution:

1. Filter the assets belonging to it.
2. Count available assets.
3. Count assets under maintenance.
4. Display its sites/campuses.

Checkpoint: The institution totals must match the filtered Assets page.

## 16. Add delete functionality

Before deleting, ask for confirmation:

```ts
if (!window.confirm("Delete this asset?")) return;
```

Then call:

```ts
await api(`/assets/${encodeURIComponent(asset.assetTag)}`, {
  method: "DELETE"
});
```

Close the drawer and reload the asset list after success.

Checkpoint: Delete only a test asset, not one of the assignment examples.

## 17. Apply the visual design

Build the CSS in this order:

1. Colour variables and global defaults.
2. Sidebar and navigation.
3. Top bar and buttons.
4. Welcome banner.
5. Statistics cards.
6. Panels and asset lists.
7. Tables and filters.
8. Schedule and institution cards.
9. Drawer and modal forms.
10. Loading, error, and success states.
11. Responsive rules for tablet and mobile.

Use a small palette:

```css
:root {
  --navy: #0b2442;
  --blue: #2868d8;
  --gold: #f4b526;
  --ink: #17243a;
  --muted: #6b778d;
  --line: #e5eaf1;
  --surface: #ffffff;
  --canvas: #f4f6f9;
}
```

Checkpoint: At 760px wide, the sidebar should become a horizontal navigation bar and the forms should use one column.

## 18. Test the finished project

Test in this order:

1. Start `library_service`.
2. Start the new web client.
3. Confirm that five sample assets load.
4. Search and filter assets.
5. Open the asset drawer.
6. Create and delete a test asset.
7. Loan an available asset.
8. Book an available room.
9. Add a schedule.
10. Stop the backend and check the error message.
11. Run the production build.

## Suggested study schedule

| Session | Work |
| --- | --- |
| 1 | Project setup, layout, navigation, and TypeScript types |
| 2 | API proxy, data loading, and error handling |
| 3 | Overview statistics and asset catalogue |
| 4 | Search, filtering, status components, and drawer |
| 5 | Asset creation and deletion |
| 6 | Loans, bookings, and schedules |
| 7 | Institutions, responsive CSS, and testing |

Do not move to the next session until you can explain the current code without reading it line by line.
