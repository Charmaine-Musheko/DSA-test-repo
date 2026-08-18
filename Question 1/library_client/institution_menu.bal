import ballerina/http;
import ballerina/io;

function institutionMenu(http:Client cl) {
    boolean inMenu = true;
    while inMenu {
        io:println("\n-- Institution Management --");
        io:println("1. List institutions");
        io:println("2. Add an institution");
        io:println("3. Remove an institution");
        io:println("4. Add a site / campus to an institution");
        io:println("5. Remove a site / campus from an institution");
        io:println("0. Back to main menu");
        string choice = io:readln("Select an option: ").trim();

        if choice == "1" {
            listInstitutions(cl);
        } else if choice == "2" {
            addInstitution(cl);
        } else if choice == "3" {
            removeInstitution(cl);
        } else if choice == "4" {
            addSite(cl);
        } else if choice == "5" {
            removeSite(cl);
        } else if choice == "0" {
            inMenu = false;
        } else {
            io:println("Invalid option.");
        }
    }
}

function listInstitutions(http:Client cl) {
    json[]? all = fetchInstitutionsList(cl);
    if all is () {
        return;
    }
    if all.length() == 0 {
        io:println("No institutions registered yet.");
        return;
    }
    string[][] rows = [];
    int i = 1;
    foreach json inst in all {
        if inst is map<json> {
            rows.push([i.toString(), inst["name"].toString(), inst["sites"].toString()]);
            i += 1;
        }
    }
    printTable(["#", "Institution", "Sites"], rows);
}

function addInstitution(http:Client cl) {
    string? name = promptRequired("Institution name");
    if name is () {
        return;
    }
    json payload = {name: name, sites: []};
    var [code, body] = sendRequest(cl, "POST", "/institutions", payload);
    reportOutcome(code, body, "Institution added.");
}

function removeInstitution(http:Client cl) {
    string? name = pickInstitution(cl, "Pick an institution to remove");
    if name is () {
        return;
    }
    io:println(string `Removing '${name}' cannot be undone (it will fail if assets still reference it). Type YES to confirm, anything else cancels.`);
    string confirm = io:readln("> ").trim();
    if confirm != "YES" {
        io:println("Cancelled.");
        return;
    }
    var [code, body] = sendRequest(cl, "DELETE", string `/institutions/${name}`);
    reportOutcome(code, body, "Institution removed.");
}

function addSite(http:Client cl) {
    string? name = pickInstitution(cl, "Add a site to which institution?");
    if name is () {
        return;
    }
    string? site = promptRequired("New site / campus name");
    if site is () {
        return;
    }
    json payload = {site: site};
    var [code, body] = sendRequest(cl, "POST", string `/institutions/${name}/sites`, payload);
    reportOutcome(code, body, "Site added.");
}

function removeSite(http:Client cl) {
    string? name = pickInstitution(cl, "Remove a site from which institution?");
    if name is () {
        return;
    }
    string? site = pickSite(cl, name);
    if site is () {
        return;
    }
    var [code, body] = sendRequest(cl, "DELETE", string `/institutions/${name}/sites/${site}`);
    reportOutcome(code, body, "Site removed.");
}
