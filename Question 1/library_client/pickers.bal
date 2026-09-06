import ballerina/http;
import ballerina/io;

function fetchAssetsList(http:Client cl) returns json[]? {
    var [code, body] = sendRequest(cl, "GET", "/assets");
    if !isSuccess(code) {
        io:println("Failed to load assets: ", extractMessage(body));
        return ();
    }
    if body is json[] {
        return body;
    }
    return [];
}

function fetchInstitutionsList(http:Client cl) returns json[]? {
    var [code, body] = sendRequest(cl, "GET", "/institutions");
    if !isSuccess(code) {
        io:println("Failed to load institutions: ", extractMessage(body));
        return ();
    }
    if body is json[] {
        return body;
    }
    return [];
}

function fetchInstitutionSites(http:Client cl, string institutionName) returns string[]? {
    var [code, body] = sendRequest(cl, "GET", string `/institutions/${institutionName}`);
    if !isSuccess(code) {
        io:println("Failed to load sites: ", extractMessage(body));
        return ();
    }
    if body is map<json> {
        json? sitesJson = body["sites"];
        if sitesJson is json[] {
            string[] sites = [];
            foreach json s in sitesJson {
                sites.push(s.toString());
            }
            return sites;
        }
    }
    return [];
}

function readPick(int total) returns int? {
    string raw = io:readln("Select a number (0 to cancel): ").trim();
    if isBackInput(raw) {
        return ();
    }
    int|error idx = int:fromString(raw);
    if idx is error || idx < 1 || idx > total {
        io:println("Invalid selection — cancelled.");
        return ();
    }
    return idx;
}

function pickAssetTag(http:Client cl, string title, string filterStatus = "") returns string? {
    json[]? all = fetchAssetsList(cl);
    if all is () {
        return ();
    }
    json[] filtered = [];
    foreach json a in all {
        if a is map<json> {
            if filterStatus == "" || a["status"].toString() == filterStatus {
                filtered.push(a);
            }
        }
    }
    if filtered.length() == 0 {
        if filterStatus == "" {
            io:println("There are no assets yet.");
        } else {
            io:println(string `No assets are currently ${filterStatus}.`);
        }
        return ();
    }

    io:println("\n-- " + title + " --");
    string[][] rows = [];
    int i = 1;
    foreach json a in filtered {
        if a is map<json> {
            rows.push([i.toString(), a["assetTag"].toString(), a["name"].toString(),
                a["institution"].toString(), a["site"].toString(), a["status"].toString()]);
            i += 1;
        }
    }
    printTable(["#", "Tag", "Name", "Institution", "Site", "Status"], rows);

    int? idx = readPick(filtered.length());
    if idx is () {
        return ();
    }
    json chosen = filtered[idx - 1];
    if chosen is map<json> {
        return chosen["assetTag"].toString();
    }
    return ();
}

function pickInstitution(http:Client cl, string title) returns string? {
    json[]? all = fetchInstitutionsList(cl);
    if all is () {
        return ();
    }
    if all.length() == 0 {
        io:println("No institutions are registered yet.");
        return ();
    }

    io:println("\n-- " + title + " --");
    string[][] rows = [];
    int i = 1;
    foreach json inst in all {
        if inst is map<json> {
            json? sitesJson = inst["sites"];
            int siteCount = sitesJson is json[] ? sitesJson.length() : 0;
            rows.push([i.toString(), inst["name"].toString(), siteCount.toString()]);
            i += 1;
        }
    }
    printTable(["#", "Institution", "# Sites"], rows);

    int? idx = readPick(all.length());
    if idx is () {
        return ();
    }
    json chosen = all[idx - 1];
    if chosen is map<json> {
        return chosen["name"].toString();
    }
    return ();
}

function pickSite(http:Client cl, string institutionName, string[] extra = []) returns string? {
    string[]? sites = fetchInstitutionSites(cl, institutionName);
    if sites is () {
        return ();
    }
    if sites.length() == 0 && extra.length() == 0 {
        io:println(string `'${institutionName}' has no sites registered yet.`);
        return ();
    }

    io:println(string `\n-- Sites for ${institutionName} --`);
    int i = 1;
    foreach string s in sites {
        io:println(string `  ${i}. ${s}`);
        i += 1;
    }
    foreach string e in extra {
        io:println(string `  ${i}. ${e}`);
        i += 1;
    }

    int total = sites.length() + extra.length();
    int? idx = readPick(total);
    if idx is () {
        return ();
    }
    if idx <= sites.length() {
        return sites[idx - 1];
    }
    return extra[idx - sites.length() - 1];
}

function pickAssetStatus(string title = "Select a status") returns string? {
    string[] statuses = ["AVAILABLE", "LOANED_OUT", "OCCUPIED", "UNDER_MAINTENANCE", "DISPOSED"];
    io:println("\n-- " + title + " --");
    int i = 1;
    foreach string s in statuses {
        io:println(string `  ${i}. ${s}`);
        i += 1;
    }

    int? idx = readPick(statuses.length());
    if idx is () {
        return ();
    }
    return statuses[idx - 1];
}

const string SCHEDULE_TYPE_OTHER = "Other (type it myself)";

function pickScheduleType() returns string? {
    string[] types = ["MAINTENANCE", "SERVICING", "BOOKING", "LOAN", SCHEDULE_TYPE_OTHER];
    io:println("\n-- Schedule type --");
    int i = 1;
    foreach string t in types {
        io:println(string `  ${i}. ${t}`);
        i += 1;
    }

    int? idx = readPick(types.length());
    if idx is () {
        return ();
    }
    if types[idx - 1] == SCHEDULE_TYPE_OTHER {
        string? custom = promptRequired("Enter the type");
        return custom;
    }
    return types[idx - 1];
}

function pickScheduleStatus() returns string? {
    string[] statuses = ["PENDING", "COMPLETED", "CANCELLED"];
    io:println("\n-- Schedule status --");
    int i = 1;
    foreach string s in statuses {
        io:println(string `  ${i}. ${s}`);
        i += 1;
    }

    int? idx = readPick(statuses.length());
    if idx is () {
        return ();
    }
    return statuses[idx - 1];
}

function pickSchedule(http:Client cl, string assetTag, string title) returns string? {
    var [code, body] = sendRequest(cl, "GET", string `/assets/${assetTag}/schedules`);
    if !isSuccess(code) {
        io:println("Failed to load schedules: ", extractMessage(body));
        return ();
    }
    if body !is json[] || body.length() == 0 {
        io:println("This asset has no schedules yet.");
        return ();
    }
    json[] schedules = body;

    io:println("\n-- " + title + " --");
    string[][] rows = [];
    int i = 1;
    foreach json s in schedules {
        if s is map<json> {
            rows.push([i.toString(), s["scheduleId"].toString(), s["type"].toString(),
                s["dueDate"].toString(), s["status"].toString(), s["description"].toString()]);
            i += 1;
        }
    }
    printTable(["#", "ID", "Type", "Due", "Status", "Description"], rows);

    int? idx = readPick(schedules.length());
    if idx is () {
        return ();
    }
    json chosen = schedules[idx - 1];
    if chosen is map<json> {
        return chosen["scheduleId"].toString();
    }
    return ();
}
