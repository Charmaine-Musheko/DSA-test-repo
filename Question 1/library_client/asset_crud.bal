import ballerina/http;
import ballerina/io;

const string NEW_SITE_OPTION = "Other (type a new site)";

function assetCrudMenu(http:Client cl) {
    boolean inMenu = true;
    while inMenu {
        io:println("\n-- Asset Management --");
        io:println("1. Create a new asset");
        io:println("2. View a single asset (full detail)");
        io:println("3. Update an asset's description / status");
        io:println("4. Delete an asset");
        io:println("0. Back to main menu");
        string choice = io:readln("Select an option: ").trim();

        if choice == "1" {
            createAsset(cl);
        } else if choice == "2" {
            viewAsset(cl);
        } else if choice == "3" {
            updateAsset(cl);
        } else if choice == "4" {
            deleteAsset(cl);
        } else if choice == "0" {
            inMenu = false;
        } else {
            io:println("Invalid option.");
        }
    }
}

function createAsset(http:Client cl) {
    string? institution = pickInstitution(cl, "Which institution is this asset at?");
    if institution is () {
        return;
    }

    string? sitePick = pickSite(cl, institution, [NEW_SITE_OPTION]);
    if sitePick is () {
        return;
    }
    string site;
    if sitePick == NEW_SITE_OPTION {
        string? customSite = promptRequired("New site / campus name");
        if customSite is () {
            return;
        }
        site = customSite;
    } else {
        site = sitePick;
    }

    string? name = promptRequired("Name");
    if name is () {
        return;
    }
    string description = io:readln("Description (optional): ").trim();

    string? dateAcquired = promptDate("Date acquired");
    if dateAcquired is () {
        return;
    }

    string? status = pickAssetStatus("What status should this asset start in?");
    if status is () {
        return;
    }

    string suggestedTag = generateAssetTag(cl);
    string tagInput = io:readln(string `Asset tag [${suggestedTag}] (Enter to accept, or type your own, 0 to cancel): `).trim();
    if isBackInput(tagInput) {
        return;
    }
    string tag = tagInput.length() > 0 ? tagInput : suggestedTag;

    json payload = {
        assetTag: tag,
        name: name,
        description: description,
        institution: institution,
        site: site,
        dateAcquired: dateAcquired,
        status: status,
        components: [],
        schedules: [],
        workOrders: []
    };
    var [code, body] = sendRequest(cl, "POST", "/assets", payload);
    reportOutcome(code, body, string `Asset created: ${tag}`);
}

function generateAssetTag(http:Client cl) returns string {
    json[]? all = fetchAssetsList(cl);
    map<boolean> existing = {};
    int count = 0;
    if all is json[] {
        count = all.length();
        foreach json a in all {
            if a is map<json> {
                existing[a["assetTag"].toString()] = true;
            }
        }
    }
    int n = count + 1;
    string candidate = string `AST-${padNumber(n)}`;
    while existing.hasKey(candidate) {
        n += 1;
        candidate = string `AST-${padNumber(n)}`;
    }
    return candidate;
}

function padNumber(int n) returns string {
    string s = n.toString();
    while s.length() < 3 {
        s = "0" + s;
    }
    return s;
}

function viewAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to view");
    if tag is () {
        return;
    }
    var [code, body] = sendRequest(cl, "GET", string `/assets/${tag}`);
    if !isSuccess(code) {
        io:println("Failed: ", extractMessage(body));
        return;
    }
    printAssetDetail(body);
}

function updateAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to update");
    if tag is () {
        return;
    }
    var [getCode, current] = sendRequest(cl, "GET", string `/assets/${tag}`);
    if !isSuccess(getCode) {
        io:println("Failed: ", extractMessage(current));
        return;
    }
    map<json> m = current is map<json> ? current : {};

    string description = io:readln("New description (blank keeps current): ").trim();
    if description.length() > 0 {
        m["description"] = description;
    }

    io:println("Current status: " + m["status"].toString());
    string? status = pickAssetStatus("New status (0 keeps the current status)");
    if status is string {
        m["status"] = status;
    }

    var [code, body] = sendRequest(cl, "PUT", string `/assets/${tag}`, m);
    reportOutcome(code, body, "Asset updated.");
}

function deleteAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to delete");
    if tag is () {
        return;
    }
    io:println(string `Deleting '${tag}' cannot be undone. Type YES to confirm, anything else cancels.`);
    string confirm = io:readln("> ").trim();
    if confirm != "YES" {
        io:println("Cancelled.");
        return;
    }
    var [code, body] = sendRequest(cl, "DELETE", string `/assets/${tag}`);
    reportOutcome(code, body, "Asset deleted.");
}
