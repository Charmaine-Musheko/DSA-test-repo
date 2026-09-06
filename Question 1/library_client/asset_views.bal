import ballerina/http;
import ballerina/io;

const string ALL_SITES_OPTION = "All sites at this institution";

function globalView(http:Client cl) {
    var [code, body] = sendRequest(cl, "GET", "/assets");
    if !isSuccess(code) {
        io:println("Failed to load assets: ", extractMessage(body));
        return;
    }
    printAssetList(body);
}

function campusView(http:Client cl) {
    string? institution = pickInstitution(cl, "Filter by institution");
    if institution is () {
        return;
    }
    string? site = pickSite(cl, institution, [ALL_SITES_OPTION]);
    if site is () {
        return;
    }

    string path = site == ALL_SITES_OPTION
        ? string `/assets/institution/${institution}`
        : string `/assets/institution/${institution}/site/${site}`;

    var [code, body] = sendRequest(cl, "GET", path);
    if !isSuccess(code) {
        io:println("Failed to load assets: ", extractMessage(body));
        return;
    }
    printAssetList(body);
}

function overdueDashboard(http:Client cl) {
    var [code, body] = sendRequest(cl, "GET", "/assets/overdue");
    if !isSuccess(code) {
        io:println("Failed to load overdue assets: ", extractMessage(body));
        return;
    }
    io:println("\n*** OVERDUE ITEMS ***");
    printAssetList(body);
}

function printAssetList(json body) {
    if body !is json[] {
        io:println("(unexpected response)");
        return;
    }
    json[] arr = body;
    io:println(string `Found ${arr.length()} asset(s):`);
    if arr.length() == 0 {
        return;
    }
    string[][] rows = [];
    int i = 1;
    foreach json a in arr {
        if a is map<json> {
            rows.push([i.toString(), a["assetTag"].toString(), a["name"].toString(),
                a["institution"].toString(), a["site"].toString(), a["status"].toString()]);
            i += 1;
        }
    }
    printTable(["#", "Tag", "Name", "Institution", "Site", "Status"], rows);
}

function printAssetDetail(json a) {
    if a !is map<json> {
        io:println("(unexpected response)");
        return;
    }
    io:println("\n---- Asset detail ----");
    io:println("Tag        : " + a["assetTag"].toString());
    io:println("Name       : " + a["name"].toString());
    io:println("Description: " + a["description"].toString());
    io:println("Institution: " + a["institution"].toString());
    io:println("Site       : " + a["site"].toString());
    io:println("Acquired   : " + a["dateAcquired"].toString());
    io:println("Status     : " + a["status"].toString());

    json? comps = a["components"];
    if comps is json[] {
        io:println(string `Components (${comps.length()}):`);
        foreach json c in comps {
            if c is map<json> {
                io:println(string `  - ${c["compId"].toString()}: ${c["name"].toString()}`);
            }
        }
    }

    json? scheds = a["schedules"];
    if scheds is json[] {
        io:println(string `Schedules (${scheds.length()}):`);
        foreach json s in scheds {
            printSchedule(s);
        }
    }

    json? wos = a["workOrders"];
    if wos is json[] {
        io:println(string `Work orders (${wos.length()}):`);
        foreach json w in wos {
            if w is map<json> {
                io:println(string `  - ${w["orderId"].toString()} [${w["status"].toString()}]: ${w["description"].toString()}`);
                json? tasks = w["tasks"];
                if tasks is json[] {
                    foreach json t in tasks {
                        if t is map<json> {
                            io:println(string `      * ${t["taskId"].toString()}: ${t["description"].toString()} (done: ${t["completed"].toString()})`);
                        }
                    }
                }
            }
        }
    }
}

function printSchedule(json s) {
    if s is map<json> {
        io:println(string `  - ${s["scheduleId"].toString()} [${s["type"].toString()}] due ${s["dueDate"].toString()} (${s["status"].toString()}): ${s["description"].toString()}`);
    }
}
