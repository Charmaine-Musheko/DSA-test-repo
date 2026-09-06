# Required Commands

These commands are written for Windows PowerShell. Run them one section at a time rather than pasting the entire document into a terminal.

## 1. Check the required software

```powershell
node --version
npm --version
bal version
```

You need Node.js, npm, and Ballerina. If one of these commands is not recognized, install that program before continuing.

## 2. Go to the assignment folder

```powershell
Set-Location "C:\Users\Charmaine.Musheko\Downloads\Question 1\Question 1"
```

Check the existing folders:

```powershell
Get-ChildItem
```

You should see `library_service` and `library_client`.

## 3. Create your practice frontend

Create a separate Next.js App Router project:

```powershell
npx create-next-app@latest your_library_web --ts --eslint --tailwind --app --turbopack --use-npm --no-src-dir --import-alias "@/*" --disable-git --yes
```

This creates a folder named `your_library_web`. The command uses TypeScript, ESLint, Tailwind CSS, the App Router, Turbopack, and npm.

Enter the new folder:

```powershell
Set-Location ".\your_library_web"
```

Confirm its files:

```powershell
Get-ChildItem
Get-ChildItem ".\app"
```

The current `create-next-app` options are documented by the official Next.js CLI documentation.

## 4. Start the empty frontend

```powershell
npm run dev
```

Open this address in your browser:

```text
http://localhost:3000
```

Stop the development server with:

```text
Ctrl+C
```

## 5. Start the Ballerina backend

Open a second PowerShell terminal:

```powershell
Set-Location "C:\Users\Charmaine.Musheko\Downloads\Question 1\Question 1\library_service"
bal run
```

The backend should listen at:

```text
http://localhost:8080/library
```

Keep this terminal open while using the frontend.

## 6. Check the backend before writing frontend code

Open a third PowerShell terminal and run:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/assets" -Method Get
```

Check institutions:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/institutions" -Method Get
```

Check overdue assets:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/assets/overdue" -Method Get
```

If these fail, fix or start the backend before working on the website.

## 7. Create the API proxy folders

From `your_library_web`, create the dynamic API-route folders:

```powershell
New-Item -ItemType Directory -Force -Path ".\app\api\library\[...path]"
```

Create the route file in your editor:

```text
app/api/library/[...path]/route.ts
```

Use the proxy instructions in Phase 5 of `CODING_PLAN.md`.

## 8. Check the proxy

Start the frontend again:

```powershell
npm run dev
```

In a different terminal, test the proxy:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets" -Method Get
```

Test the institution route:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/institutions" -Method Get
```

The results should match the direct Ballerina requests.

## 9. Useful commands while coding

Return to the practice frontend from anywhere:

```powershell
Set-Location "C:\Users\Charmaine.Musheko\Downloads\Question 1\Question 1\your_library_web"
```

Start development:

```powershell
npm run dev
```

Check TypeScript and create a production build:

```powershell
npm run build
```

Run ESLint:

```powershell
npx eslint .
```

Reinstall packages from `package-lock.json`:

```powershell
npm ci
```

Only use `npm ci` after the project has a `package-lock.json` file.

## 10. Test creating an asset directly against Ballerina

Create a temporary payload:

```powershell
$assetPayload = @{
    assetTag = "STUDENT-TEST-001"
    name = "Student Test Laptop"
    description = "Temporary asset used while learning the frontend"
    institution = "University of Namibia"
    site = "Khomasdal Campus"
    dateAcquired = "2026-08-17"
    status = "AVAILABLE"
    components = @()
    schedules = @()
    workOrders = @()
} | ConvertTo-Json -Depth 6
```

Send it to the server:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/assets" -Method Post -ContentType "application/json" -Body $assetPayload
```

Retrieve it:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/assets/STUDENT-TEST-001" -Method Get
```

Delete the temporary asset:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/library/assets/STUDENT-TEST-001" -Method Delete
```

## 11. Test creating an asset through the web proxy

Recreate `$assetPayload` using the command above, then send it through the frontend:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets" -Method Post -ContentType "application/json" -Body $assetPayload
```

Delete it through the proxy:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/STUDENT-TEST-001" -Method Delete
```

This proves that the request travels from the web project to the Ballerina service.

## 12. Test a loan request

Create the payload:

```powershell
$loanPayload = @{
    borrower = "Student Name"
    dueDate = "2026-09-10"
    description = "Distributed systems research"
} | ConvertTo-Json
```

Send it through the frontend proxy. Replace the tag with an available asset:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-LIB-BK-045/loan" -Method Post -ContentType "application/json" -Body $loanPayload
```

Return that asset when finished:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-LIB-BK-045/return" -Method Post
```

## 13. Test a booking request

Create the payload:

```powershell
$bookingPayload = @{
    bookedBy = "DSA612S Group"
    dueDate = "2026-09-12"
    description = "Assignment discussion"
} | ConvertTo-Json
```

Book the sample meeting room:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-FAC-MR-007/book" -Method Post -ContentType "application/json" -Body $bookingPayload
```

Release it afterward:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-FAC-MR-007/release" -Method Post
```

## 14. Test adding a schedule

```powershell
$schedulePayload = @{
    scheduleId = "STUDENT-SCH-001"
    type = "MAINTENANCE"
    dueDate = "2026-09-15"
    description = "Practice maintenance schedule"
    status = "PENDING"
} | ConvertTo-Json
```

Add the schedule:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-LIB-BK-045/schedules" -Method Post -ContentType "application/json" -Body $schedulePayload
```

Remove it when testing is complete:

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/library/assets/NUST-LIB-BK-045/schedules/STUDENT-SCH-001" -Method Delete
```

## 15. Final verification commands

Build the backend:

```powershell
Set-Location "C:\Users\Charmaine.Musheko\Downloads\Question 1\Question 1\library_service"
bal build
```

Build the practice frontend:

```powershell
Set-Location "C:\Users\Charmaine.Musheko\Downloads\Question 1\Question 1\your_library_web"
npm run build
```

Run frontend linting:

```powershell
npx eslint .
```

The rebuild is ready when all three commands complete without errors.

## 16. Common troubleshooting commands

Check whether the backend is responding:

```powershell
Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8080/library/assets" -TimeoutSec 10
```

Check whether the frontend is responding:

```powershell
Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:3000" -TimeoutSec 10
```

See which process is using port 3000:

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
```

See which process is using port 8080:

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
```

Do not stop a process unless you started it and are certain it belongs to your frontend or backend.
