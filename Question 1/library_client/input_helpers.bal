import ballerina/io;

function isBackInput(string s) returns boolean {
    string lower = s.trim().toLowerAscii();
    return lower == "0" || lower == "b" || lower == "back";
}

function promptRequired(string label) returns string? {
    while true {
        string input = io:readln(label + " (0 to cancel): ").trim();
        if isBackInput(input) {
            return ();
        }
        if input.length() > 0 {
            return input;
        }
        io:println("This field cannot be empty - please try again.");
    }
}

function promptDate(string label) returns string? {
    while true {
        string input = io:readln(label + " (YYYY-MM-DD, 0 to cancel): ").trim();
        if isBackInput(input) {
            return ();
        }
        if isValidIsoDate(input) {
            return input;
        }
        io:println("Please enter a date as YYYY-MM-DD, e.g. 2026-09-01.");
    }
}

function isValidIsoDate(string s) returns boolean {
    if s.length() != 10 {
        return false;
    }
    string yyyy = s.substring(0, 4);
    string sep1 = s.substring(4, 5);
    string mm = s.substring(5, 7);
    string sep2 = s.substring(7, 8);
    string dd = s.substring(8, 10);
    if sep1 != "-" || sep2 != "-" {
        return false;
    }
    if !isAllDigits(yyyy) || !isAllDigits(mm) || !isAllDigits(dd) {
        return false;
    }
    int|error monthVal = int:fromString(mm);
    int|error dayVal = int:fromString(dd);
    if monthVal is error || dayVal is error {
        return false;
    }
    if monthVal < 1 || monthVal > 12 {
        return false;
    }
    if dayVal < 1 || dayVal > 31 {
        return false;
    }
    return true;
}

function isAllDigits(string s) returns boolean {
    if s.length() == 0 {
        return false;
    }
    int i = 0;
    while i < s.length() {
        string c = s.substring(i, i + 1);
        if c < "0" || c > "9" {
            return false;
        }
        i += 1;
    }
    return true;
}

function padRight(string s, int width, string fill = " ") returns string {
    string result = s;
    while result.length() < width {
        result = result + fill;
    }
    return result;
}

function printTable(string[] headers, string[][] rows) {
    int cols = headers.length();
    int[] widths = [];
    foreach string h in headers {
        widths.push(h.length());
    }
    foreach string[] row in rows {
        int c = 0;
        foreach string cell in row {
            if c < cols && cell.length() > widths[c] {
                widths[c] = cell.length();
            }
            c += 1;
        }
    }

    string headerLine = "";
    string sepLine = "";
    int hc = 0;
    foreach string h in headers {
        headerLine = headerLine + padRight(h, widths[hc]) + "  ";
        sepLine = sepLine + padRight("", widths[hc], "-") + "  ";
        hc += 1;
    }
    io:println(headerLine);
    io:println(sepLine);

    foreach string[] row in rows {
        string line = "";
        int rc = 0;
        foreach string cell in row {
            if rc < cols {
                line = line + padRight(cell, widths[rc]) + "  ";
            }
            rc += 1;
        }
        io:println(line);
    }
}
