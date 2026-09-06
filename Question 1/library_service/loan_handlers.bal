import ballerina/http;
function handleLoanAsset(string assetTag, LoanRequest req) returns Asset|http:NotFound|http:Conflict {
    Asset? found = assetsTable[assetTag];
    if found is () {
        return <http:NotFound>{body: <ErrorPayload>{message: string `Asset '${assetTag}' not found`}};
    }
    Asset a = found;
    if a.status != "AVAILABLE" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not AVAILABLE (current status: ${a.status})`}};
    }
    a.status = "LOANED_OUT";
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
    if a.status != "LOANED_OUT" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not currently on loan (current status: ${a.status})`}};
    }
    a.status = "AVAILABLE";
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
    if a.status != "AVAILABLE" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not AVAILABLE (current status: ${a.status})`}};
    }
    a.status = "OCCUPIED";
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
    if a.status != "OCCUPIED" {
        return <http:Conflict>{body: <ErrorPayload>{message: string `Asset is not currently OCCUPIED (current status: ${a.status})`}};
    }
    a.status = "AVAILABLE";
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
