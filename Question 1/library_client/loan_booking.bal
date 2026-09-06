import ballerina/http;
import ballerina/io;

function loanBookingMenu(http:Client cl) {
    boolean inMenu = true;
    while inMenu {
        io:println("\n-- Loan / Booking --");
        io:println("1. Loan an asset");
        io:println("2. Return a loaned asset");
        io:println("3. Book a space (lab / meeting room)");
        io:println("4. Release a booked space");
        io:println("0. Back to main menu");
        string choice = io:readln("Select an option: ").trim();

        if choice == "1" {
            loanAsset(cl);
        } else if choice == "2" {
            returnAsset(cl);
        } else if choice == "3" {
            bookAsset(cl);
        } else if choice == "4" {
            releaseAsset(cl);
        } else if choice == "0" {
            inMenu = false;
        } else {
            io:println("Invalid option.");
        }
    }
}

function loanAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to loan out (only AVAILABLE assets shown)", "AVAILABLE");
    if tag is () {
        return;
    }
    string? borrower = promptRequired("Borrower name");
    if borrower is () {
        return;
    }
    string? dueDate = promptDate("Due date");
    if dueDate is () {
        return;
    }
    json payload = {borrower: borrower, dueDate: dueDate};
    var [code, body] = sendRequest(cl, "POST", string `/assets/${tag}/loan`, payload);
    reportOutcome(code, body, "Asset loaned out successfully.");
}

function returnAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick an asset to return (only LOANED_OUT assets shown)", "LOANED_OUT");
    if tag is () {
        return;
    }
    var [code, body] = sendRequest(cl, "POST", string `/assets/${tag}/return`);
    reportOutcome(code, body, "Asset returned successfully.");
}

function bookAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick a space to book (only AVAILABLE assets shown)", "AVAILABLE");
    if tag is () {
        return;
    }
    string? bookedBy = promptRequired("Booked by");
    if bookedBy is () {
        return;
    }
    string? dueDate = promptDate("Booking end date");
    if dueDate is () {
        return;
    }
    json payload = {bookedBy: bookedBy, dueDate: dueDate};
    var [code, body] = sendRequest(cl, "POST", string `/assets/${tag}/book`, payload);
    reportOutcome(code, body, "Space booked successfully.");
}

function releaseAsset(http:Client cl) {
    string? tag = pickAssetTag(cl, "Pick a space to release (only OCCUPIED assets shown)", "OCCUPIED");
    if tag is () {
        return;
    }
    var [code, body] = sendRequest(cl, "POST", string `/assets/${tag}/release`);
    reportOutcome(code, body, "Space released successfully.");
}
