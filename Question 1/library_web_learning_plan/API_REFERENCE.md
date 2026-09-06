# API and Payload Reference

The browser calls `/api/library/...`. The web proxy forwards that request to `http://127.0.0.1:8080/library/...`.

## Assets

### List assets

```http
GET /api/library/assets
```

### Create an asset

```http
POST /api/library/assets
Content-Type: application/json
```

```json
{
  "assetTag": "NUST-LIB-001",
  "name": "Research Laptop",
  "description": "Laptop for postgraduate research",
  "institution": "Namibia University of Science and Technology",
  "site": "Main Campus - Library",
  "dateAcquired": "2026-08-17",
  "status": "AVAILABLE",
  "components": [],
  "schedules": [],
  "workOrders": []
}
```

### Read, update, or delete one asset

```http
GET    /api/library/assets/{assetTag}
PUT    /api/library/assets/{assetTag}
DELETE /api/library/assets/{assetTag}
```

## Filtering

```http
GET /api/library/assets/institution/{institution}
GET /api/library/assets/institution/{institution}/site/{site}
GET /api/library/assets/overdue
GET /api/library/assets/{assetTag}/status
```

Always use `encodeURIComponent()` when inserting tags, institution names, or site names into a URL.

## Loaning

```http
POST /api/library/assets/{assetTag}/loan
```

```json
{
  "borrower": "Anna Student",
  "dueDate": "2026-09-10",
  "description": "Research project"
}
```

Return an asset:

```http
POST /api/library/assets/{assetTag}/return
```

## Booking

```http
POST /api/library/assets/{assetTag}/book
```

```json
{
  "bookedBy": "DSA612S Group",
  "dueDate": "2026-09-10",
  "description": "Assignment meeting"
}
```

Release a booked resource:

```http
POST /api/library/assets/{assetTag}/release
```

## Schedules

```http
GET    /api/library/assets/{assetTag}/schedules
POST   /api/library/assets/{assetTag}/schedules
PUT    /api/library/assets/{assetTag}/schedules/{scheduleId}
DELETE /api/library/assets/{assetTag}/schedules/{scheduleId}
```

```json
{
  "scheduleId": "SCH-101",
  "type": "MAINTENANCE",
  "dueDate": "2026-09-15",
  "description": "Quarterly inspection",
  "status": "PENDING"
}
```

## Institutions

```http
GET    /api/library/institutions
POST   /api/library/institutions
GET    /api/library/institutions/{name}
DELETE /api/library/institutions/{name}
```

```json
{
  "name": "Example University",
  "sites": ["Main Campus", "Northern Campus"]
}
```

## Components

```http
GET    /api/library/assets/{assetTag}/components
POST   /api/library/assets/{assetTag}/components
DELETE /api/library/assets/{assetTag}/components/{compId}
```

```json
{
  "compId": "C101",
  "name": "Battery",
  "description": "Replacement laptop battery"
}
```

## Work orders and tasks

```http
GET    /api/library/assets/{assetTag}/workorders
POST   /api/library/assets/{assetTag}/workorders
PUT    /api/library/assets/{assetTag}/workorders/{orderId}
DELETE /api/library/assets/{assetTag}/workorders/{orderId}
```

```json
{
  "orderId": "WO-101",
  "status": "OPEN",
  "description": "Screen is flickering",
  "tasks": []
}
```

Task routes:

```http
POST   /api/library/assets/{assetTag}/workorders/{orderId}/tasks
PUT    /api/library/assets/{assetTag}/workorders/{orderId}/tasks/{taskId}
DELETE /api/library/assets/{assetTag}/workorders/{orderId}/tasks/{taskId}
```

```json
{
  "taskId": "T1",
  "description": "Test the display cable",
  "completed": false
}
```

## Expected HTTP responses

| Status | Meaning |
| --- | --- |
| 200 | Request succeeded |
| 201 | Record created |
| 400 | Invalid payload or path/payload mismatch |
| 404 | Requested record does not exist |
| 409 | Duplicate record or invalid status transition |
| 503 | Web client cannot reach the Ballerina service |
