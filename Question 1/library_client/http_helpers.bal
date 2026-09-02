import ballerina/http;
import ballerina/io;

function sendRequest(http:Client cl, string httpMethod, string path, json? payload = ()) returns [int, json] {
    http:Response|error resp;
    json body = payload is () ? {} : payload;

    // Show the message that the client sends to the service.
    // This makes the request-response communication visible during the demo.
    io:println("\n--- REQUEST SENT TO SERVER ---");
    io:println(httpMethod + " " + BASE_URL + path);
    if payload is () {
        io:println("Request payload: (none)");
    } else {
        io:println("Content-Type: application/json");
        io:println("Request payload:");
        io:println(payload);
    }

    if httpMethod == "GET" {
        resp = cl->get(path);
    } else if httpMethod == "POST" {
        resp = cl->post(path, body);
    } else if httpMethod == "PUT" {
        resp = cl->put(path, body);
    } else {
        resp = cl->delete(path, body);
    }

    if resp is error {
        io:println("\n--- RESPONSE FROM SERVER ---");
        io:println("No HTTP response was received.");
        io:println("Error: ", resp.message());
        io:println("Check whether library_service is running on " + BASE_URL + ".");
        return [0, {}];
    }

    http:Response r = resp;
    json|error respBody = r.getJsonPayload();
    json outBody = respBody is json ? respBody : {};

    // Show the status code and JSON returned by the service.
    io:println("\n--- RESPONSE FROM SERVER ---");
    io:println("Status code: " + r.statusCode.toString());
    io:println("Response payload:");
    io:println(outBody);
    io:println("----------------------------");

    return [r.statusCode, outBody];
}

function extractMessage(json payload) returns string {
    if payload is map<json> {
        json? m = payload["message"];
        if m is string {
            return m;
        }
    }
    return "(no further details)";
}

function isSuccess(int statusCode) returns boolean {
    return statusCode >= 200 && statusCode < 300;
}

function reportOutcome(int code, json body, string successMessage) {
    if isSuccess(code) {
        io:println("OK (" + code.toString() + "): " + successMessage);
    } else {
        io:println("FAILED (" + code.toString() + "): " + extractMessage(body));
    }
}
