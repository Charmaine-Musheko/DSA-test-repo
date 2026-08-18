import ballerina/http;
import ballerina/io;
import ballerina/time;

function scheduleManagerMenu(http:Client cl) {
    boolean inMenu = true;
    while inMenu {
        io:println("\n-- Schedule Manager --");
        io:println("1. View schedules for an asset");
        io:println("2. Add a schedule");
        io:println("3. Update a schedule");
        io:println("4. Remove a schedule");
        io:println("0. Back to main menu");
        string choice = io:readln("Select an option: ").trim();

        if choice == "1" {
            viewSchedules(cl);
        } else if choice == "2" {
            addSchedule(cl);
        } else if choice == "3" {
            updateSchedule(cl);
        } else if choice == "4" {
            removeSchedule(cl);
        } else if choice == "0" {
            inMenu = false;
        } else {
            io:println("Invalid option.");
        }
    }
}

function viewSchedules(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to view schedules for");
    if tag is () {
        return;
    }
    var [code, body] = sendRequest(cl, "GET", string `/assets/${tag}/schedules`);
    if !isSuccess(code) {
        io:println("Failed: ", extractMessage(body));
        return;
    }
    if body !is json[] {
        io:println("(unexpected response)");
        return;
    }
    if body.length() == 0 {
        io:println("This asset has no schedules yet.");
        return;
    }
    string[][] rows = [];
    int i = 1;
    foreach json s in body {
        if s is map<json> {
            rows.push([i.toString(), s["scheduleId"].toString(), s["type"].toString(),
                s["dueDate"].toString(), s["status"].toString(), s["description"].toString()]);
            i += 1;
        }
    }
    printTable(["#", "ID", "Type", "Due", "Status", "Description"], rows);
}

function addSchedule(http:Client cl) {
    string? tag = pickAssetTag(cl, "Add a schedule to which asset?");
    if tag is () {
        return;
    }
    string? sType = pickScheduleType();
    if sType is () {
        return;
    }
    string? dueDate = promptDate("Due date");
    if dueDate is () {
        return;
    }
    string description = io:readln("Description (optional): ").trim();
    string scheduleId = generateScheduleId(sType);
    io:println(string `Schedule id: ${scheduleId}`);

    json payload = {scheduleId: scheduleId, 'type: sType, dueDate: dueDate, description: description, status: "PENDING"};
    var [code, body] = sendRequest(cl, "POST", string `/assets/${tag}/schedules`, payload);
    reportOutcome(code, body, "Schedule added.");
}

function updateSchedule(http:Client cl) {
    string? tag = pickAssetTag(cl, "Update a schedule on which asset?");
    if tag is () {
        return;
    }
    string? scheduleId = pickSchedule(cl, tag, "Pick a schedule to update");
    if scheduleId is () {
        return;
    }
    string? sType = pickScheduleType();
    if sType is () {
        return;
    }
    string? dueDate = promptDate("New due date");
    if dueDate is () {
        return;
    }
    string description = io:readln("Description (optional): ").trim();
    string? status = pickScheduleStatus();
    if status is () {
        return;
    }

    json payload = {scheduleId: scheduleId, 'type: sType, dueDate: dueDate, description: description, status: status};
    var [code, body] = sendRequest(cl, "PUT", string `/assets/${tag}/schedules/${scheduleId}`, payload);
    reportOutcome(code, body, "Schedule updated.");
}

function removeSchedule(http:Client cl) {
    string? tag = pickAssetTag(cl, "Remove a schedule from which asset?");
    if tag is () {
        return;
    }
    string? scheduleId = pickSchedule(cl, tag, "Pick a schedule to remove");
    if scheduleId is () {
        return;
    }
    var [code, body] = sendRequest(cl, "DELETE", string `/assets/${tag}/schedules/${scheduleId}`);
    reportOutcome(code, body, "Schedule removed.");
}

function generateScheduleId(string sType) returns string {
    string prefix = "SCH";
    if sType == "LOAN" {
        prefix = "LN";
    } else if sType == "BOOKING" {
        prefix = "BK";
    }
    time:Utc now = time:utcNow();
    int ticks = <int>now[0];
    return string `${prefix}-${ticks}`;
}
