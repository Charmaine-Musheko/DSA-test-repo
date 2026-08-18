import ballerina/http;
import ballerina/io;

const string BASE_URL = "http://localhost:8080/library";

public function main() returns error? {
    http:Client cl = check new (BASE_URL);
    boolean running = true;

    io:println("Connected to Ministry Library / Resource Management API at " + BASE_URL);

    while running {
        printMainMenu();
        string choice = io:readln("Select an option: ");

        if choice == "1" {
            loanBookingMenu(cl);
        } else if choice == "2" {
            globalView(cl);
        } else if choice == "3" {
            campusView(cl);
        } else if choice == "4" {
            overdueDashboard(cl);
        } else if choice == "5" {
            scheduleManagerMenu(cl);
        } else if choice == "6" {
            assetCrudMenu(cl);
        } else if choice == "7" {
            institutionMenu(cl);
        } else if choice == "0" {
            running = false;
            io:println("Goodbye.");
        } else {
            io:println("Invalid option, please try again.");
        }
    }
}

function printMainMenu() {
    io:println("\n==================== MINISTRY LIBRARY / RESOURCE SYSTEM ====================");
    io:println("1. Loan / Book / Return / Release an asset");
    io:println("2. Global view      - list ALL assets across the ministry");
    io:println("3. Campus view      - filter by institution / site");
    io:println("4. Overdue dashboard");
    io:println("5. Schedule manager - add / update / remove schedules");
    io:println("6. Asset management - create / view / update / delete");
    io:println("7. Institution management - add / remove institutions & sites");
    io:println("0. Exit");
    io:println("==============================================================================");
}
