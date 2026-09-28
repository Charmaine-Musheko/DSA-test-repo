import ballerina/http;

function handleLoanAsset(string assetTag, LoanRequest req) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    // Only AVAILABLE assets can be loaned out.
    if a.status != "AVAILABLE" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not AVAILABLE (current status: ${a.status})`}};
    }
    a.status = "LOANED_OUT";
    // Record the loan as a PENDING schedule so it appears on the overdue dashboard.
    a.schedules.push({
        scheduleId: nextId("LN"),
        'type: "LOAN",
        dueDate: req.dueDate,
        description: req.description.length() > 0 ? req.description : string `Loaned to ${req.borrower}`,
        status: "PENDING"
    });
    assetsTable.put(a);
    return a;
}

function handleReturnAsset(string assetTag) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    // Return only makes sense for a LOANED_OUT asset.
    if a.status != "LOANED_OUT" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not currently on loan (current status: ${a.status})`}};
    }
    a.status = "AVAILABLE";
    // Mark the open loan schedule as COMPLETED so it no longer counts as overdue.
    Schedule[] updatedSchedules = [];
    foreach Schedule s in a.schedules {
        if s.'type == "LOAN" && s.status == "PENDING" {
            s.status = "COMPLETED";
        }
        updatedSchedules.push(s);
    }
    a.schedules = updatedSchedules;
    assetsTable.put(a);
    return a;
}

function handleBookAsset(string assetTag, BookingRequest req) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    // Rooms/labs can only be booked when AVAILABLE.
    if a.status != "AVAILABLE" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not AVAILABLE (current status: ${a.status})`}};
    }
    a.status = "OCCUPIED";
    // Bookings are also schedules (type BOOKING) so they show up in the schedule manager.
    a.schedules.push({
        scheduleId: nextId("BK"),
        'type: "BOOKING",
        dueDate: req.dueDate,
        description: req.description.length() > 0 ? req.description : string `Booked by ${req.bookedBy}`,
        status: "PENDING"
    });
    assetsTable.put(a);
    return a;
}

function handleReleaseAsset(string assetTag) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    // Release only valid for OCCUPIED assets.
    if a.status != "OCCUPIED" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not currently OCCUPIED (current status: ${a.status})`}};
    }
    a.status = "AVAILABLE";
    // Close all open BOOKING schedules.
    Schedule[] updatedSchedules = [];
    foreach Schedule s in a.schedules {
        if s.'type == "BOOKING" && s.status == "PENDING" {
            s.status = "COMPLETED";
        }
        updatedSchedules.push(s);
    }
    a.schedules = updatedSchedules;
    assetsTable.put(a);
    return a;
}


