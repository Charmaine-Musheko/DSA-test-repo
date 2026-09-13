import ballerina/io;
import ballerina/grpc;

// ============================================================================
// CLIENT-SIDE SESSION STATE
// ============================================================================
//
// This object keeps track of IDs returned while this CLI application is
// running.
//
// This is NOT persistent storage. When the client exits, this information is
// lost.
//
// Option 10 uses this object to demonstrate the current CLI session state.
// ============================================================================
class SessionState {

    public string[] submittedUserIds = [];
    public string[] propertyIds = [];
    public string[] cartIds = [];
    public string[] bookingIds = [];

    public string lastPropertyId = "";
    public string lastCartId = "";
    public string lastBookingId = "";
}


// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

public function main() returns error? {

    io:println();
    io:println("============================================================");
    io:println("       NAMIBIA RENTAL PLATFORM - gRPC CLI CLIENT");
    io:println("============================================================");
    io:println();

    // -----------------------------------------------------------------------
    // Connect to the gRPC service.
    //
    // NOTE:
    // "client" is a Ballerina keyword/qualifier, therefore the variable is
    // named rentalClient instead of client.
    // -----------------------------------------------------------------------
    RentalServiceClient rentalClient =
        check new ("http://localhost:9090");

    // Client-side session information.
    SessionState session = new ();

    io:println("Connected to RentalService at http://localhost:9090");
    io:println();

    // -----------------------------------------------------------------------
    // Keep the CLI running until the user explicitly chooses Exit.
    // -----------------------------------------------------------------------
    while true {

        printMenu();

        string choice =
            io:readln("Select an option [0-10]: ").trim();

        io:println();

        // Exit is handled directly here.
        if choice == "0" {
            io:println("Closing Rental Platform CLI...");
            io:println("Goodbye.");
            break;
        }

        // Run the selected operation.
        //
        // We deliberately DO NOT use:
        //
        //     check runMenuChoice(...)
        //
        // because that would terminate the entire CLI whenever an individual
        // RPC returns an error.
        error? operationResult =
            runMenuChoice(
                choice,
                rentalClient,
                session
            );

        if operationResult is error {
            io:println();
            io:println("------------------------------------------------------------");
            io:println("OPERATION FAILED");
            io:println("------------------------------------------------------------");
            io:println(operationResult);
        }

        io:println();
        _ = io:readln("Press ENTER to return to the menu...");
        io:println();
    }

    return;
}


// ============================================================================
// MENU
// ============================================================================

function printMenu() {

    io:println("============================================================");
    io:println("                    RENTAL SERVICE MENU");
    io:println("============================================================");


    io:println("------------------------------------------------------------");
    io:println("                        0. Exit");
    io:println("------------------------------------------------------------");

    io:println("  1. Create users");
    io:println("     Client-side streaming");

    io:println();

    io:println("  2. Add property");
    io:println("     Simple RPC");

    io:println();

    io:println("  3. List available properties");
    io:println("     Server-side streaming + optional filters");

    io:println();

    io:println("  4. Search property");
    io:println("     Search using property ID");

    io:println();

    io:println("  5. Update property");
    io:println("     Update price, status, or description");

    io:println();

    io:println("  6. Book property");
    io:println("     Add property to cart");

    io:println();

    io:println("  7. Confirm booking");
    io:println("     Re-check availability and confirm");

    io:println();

    io:println("  8. Remove property");
    io:println("     Remove property and show remaining properties");

    io:println();

    io:println("  9. Run complete end-to-end demonstration");
    io:println("     Executes the original assessment scenario");

    io:println();

    io:println(" 10. Inspect CLI session state");

    io:println();

    io:println("============================================================");
}


// ============================================================================
// MENU ROUTER
// ============================================================================

function runMenuChoice(
    string choice,
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    if choice == "1" {

        return createUsersMenu(
            rentalClient,
            session
        );

    } else if choice == "2" {

        return addPropertyMenu(
            rentalClient,
            session
        );

    } else if choice == "3" {

        return listPropertiesMenu(
            rentalClient
        );

    } else if choice == "4" {

        return searchPropertyMenu(
            rentalClient,
            session
        );

    } else if choice == "5" {

        return updatePropertyMenu(
            rentalClient,
            session
        );

    } else if choice == "6" {

        return bookPropertyMenu(
            rentalClient,
            session
        );

    } else if choice == "7" {

        return confirmBookingMenu(
            rentalClient,
            session
        );

    } else if choice == "8" {

        return removePropertyMenu(
            rentalClient,
            session
        );

    } else if choice == "9" {

        return runEndToEndDemo(
            rentalClient,
            session
        );

    } else if choice == "10" {

        showSessionState(session);
        return;

    } else {

        io:println("Invalid option.");
        io:println("Please select a value between 0 and 10.");

        return;
    }
}


// ============================================================================
// OPTION 1
// CREATE USERS
//
// Rubric:
//      create_users
//      Client-side streaming
// ============================================================================

function createUsersMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("1 - CREATE USERS");
    io:println("Client-side streaming demonstration");
    io:println("============================================================");

    int userCount =
        readPositiveIntWithDefault(
            "How many users do you want to create? [2]: ",
            2
        );

    // -----------------------------------------------------------------------
    // Opening the RPC gives us a streaming client.
    // -----------------------------------------------------------------------
    CreateUsersStreamingClient userStream =
        check rentalClient->CreateUsers();

    int index = 0;

    while index < userCount {

        io:println();
        io:println(
            "---------------- User ",
            index + 1,
            " of ",
            userCount,
            " ----------------"
        );

        string userId =
            readRequired("User ID: ");

        string name =
            readRequired("Name: ");

        string email =
            readRequired("Email: ");

        UserRole role =
            readUserRole();

        string region =
            io:readln(
                "Region (optional for guest): "
            ).trim();

        // -------------------------------------------------------------------
        // Each user is sent independently through the CLIENT STREAM.
        // -------------------------------------------------------------------
        check userStream->sendUser({
            user_id: userId,
            name: name,
            email: email,
            role: role,
            region: region
        });

        session.submittedUserIds.push(userId);

        io:println(
            "User sent through stream: ",
            userId
        );

        index += 1;
    }

    // -----------------------------------------------------------------------
    // Signal that the client has finished transmitting users.
    // -----------------------------------------------------------------------
    check userStream->complete();

    // -----------------------------------------------------------------------
    // Server sends ONE response after the client stream has completed.
    // -----------------------------------------------------------------------
    CreateUsersResponse? response =
        check userStream->receiveCreateUsersResponse();

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    if response is CreateUsersResponse {

        io:println(
            "Created count : ",
            response.created_count
        );

        io:println(
            "Message       : ",
            response.message
        );

    } else {

        io:println(
            "The stream completed without a response payload."
        );
    }

    return;
}


// ============================================================================
// OPTION 2
// ADD PROPERTY
//
// Rubric:
//      add_property
//      Simple RPC
//      Returns generated property_id
// ============================================================================

function addPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("2 - ADD PROPERTY");
    io:println("Simple unary RPC demonstration");
    io:println("============================================================");

    string hostId =
        readRequired("Host ID: ");

    string name =
        readRequired("Property name: ");

    string location =
        readRequired("Location: ");

    string region =
        readRequired("Region: ");

    string propertyType =
        readRequired("Property type: ");

    float price =
        readPositiveFloat(
            "Price per night (N$): "
        );

    string description =
        readRequired("Description: ");

    AddPropertyResponse response =
        check rentalClient->AddProperty({
            host_id: hostId,
            name: name,
            location: location,
            region: region,
            property_type: propertyType,
            price_per_night: price,
            description: description
        });

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");
    io:println("Success     : ", response.success);
    io:println("Message     : ", response.message);
    io:println("Property ID : ", response.property_id);

    // -----------------------------------------------------------------------
    // Remember successful property IDs for later menu operations.
    // -----------------------------------------------------------------------
    if response.success && response.property_id != "" {

        session.propertyIds.push(
            response.property_id
        );

        session.lastPropertyId =
            response.property_id;
    }

    return;
}


// ============================================================================
// OPTION 3
// LIST AVAILABLE PROPERTIES
//
// Rubric:
//      list_available_properties
//      Server-side streaming
//      Supports optional filters
// ============================================================================

function listPropertiesMenu(
    RentalServiceClient rentalClient
) returns error? {

    io:println("============================================================");
    io:println("3 - LIST AVAILABLE PROPERTIES");
    io:println("Server-side streaming demonstration");
    io:println("============================================================");

    string useFilters =
        io:readln(
            "Apply filters? [y/N]: "
        ).trim();

    stream<Property, grpc:Error?> propertyStream;

    if useFilters == "y" ||
        useFilters == "Y" ||
        useFilters == "yes" ||
        useFilters == "YES" {

        io:println();
        io:println("Leave a filter blank to use its default value.");

        string location =
            io:readln(
                "Location/region filter: "
            ).trim();

        float minimumPrice =
            readOptionalFloat(
                "Minimum price [0]: ",
                0.0
            );

        float maximumPrice =
            readOptionalFloat(
                "Maximum price [0 = no maximum]: ",
                0.0
            );

        propertyStream =
            check rentalClient->ListAvailableProperties({
                location_filter: location,
                min_price: minimumPrice,
                max_price: maximumPrice
            });

    } else {

        // No filters.
        propertyStream =
            check rentalClient->ListAvailableProperties({});
    }

    io:println();
    io:println("---------------- STREAM RESULTS ----------------");

    int count =
        check drainAndCount(propertyStream);

    io:println();
    io:println(
        "Total properties received from stream: ",
        count
    );

    return;
}


// ============================================================================
// OPTION 4
// SEARCH PROPERTY
//
// Rubric:
//      search_property
//      Lookup by property_id
//      Returns available = true/false
// ============================================================================

function searchPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("4 - SEARCH PROPERTY");
    io:println("============================================================");

    string propertyId =
        readPropertyId(session);

    SearchPropertyResponse response =
        check rentalClient->SearchProperty({
            property_id: propertyId
        });

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    io:println(
        "Available : ",
        response.available
    );

    io:println(
        "Message   : ",
        response.message
    );

    io:println(
        "Property  : ",
        response.property
    );

    return;
}


// ============================================================================
// OPTION 5
// UPDATE PROPERTY
//
// Rubric:
//      update_property
//      Update property using property_id
//      Demonstrates:
//          - price
//          - status
//          - description
// ============================================================================

function updatePropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("5 - UPDATE PROPERTY");
    io:println("============================================================");

    string propertyId =
        readPropertyId(session);

    io:println();
    io:println("What would you like to update?");
    io:println("  1. Price");
    io:println("  2. Status");
    io:println("  3. Description");

    string updateChoice =
        io:readln(
            "Select update type [1-3]: "
        ).trim();

    UpdatePropertyResponse response;

    // -----------------------------------------------------------------------
    // PRICE
    // -----------------------------------------------------------------------
    if updateChoice == "1" {

        float newPrice =
            readPositiveFloat(
                "New price per night (N$): "
            );

        response =
            check rentalClient->UpdateProperty({
                property_id: propertyId,
                price_per_night: newPrice
            });

    // -----------------------------------------------------------------------
    // STATUS
    // -----------------------------------------------------------------------
    } else if updateChoice == "2" {

        PropertyStatus newStatus =
            readPropertyStatus();

        response =
            check rentalClient->UpdateProperty({
                property_id: propertyId,
                status: newStatus
            });

    // -----------------------------------------------------------------------
    // DESCRIPTION
    // -----------------------------------------------------------------------
    } else if updateChoice == "3" {

        string description =
            readRequired(
                "New description: "
            );

        response =
            check rentalClient->UpdateProperty({
                property_id: propertyId,
                description: description
            });

    } else {

        io:println(
            "Invalid update option."
        );

        return;
    }

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    io:println(
        "Success  : ",
        response.success
    );

    io:println(
        "Message  : ",
        response.message
    );

    io:println(
        "Property : ",
        response.property
    );

    return;
}


// ============================================================================
// OPTION 6
// BOOK PROPERTY
//
// Rubric:
//      book_property
//      Adds booking request to cart
//      Server validates supplied date range
// ============================================================================

function bookPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("6 - BOOK PROPERTY");
    io:println("Add property to cart");
    io:println("============================================================");

    string guestId =
        readRequired(
            "Guest ID: "
        );

    string propertyId =
        readPropertyId(session);

    io:println();
    io:println("Date format: YYYY-MM-DD");

    string checkIn =
        readRequired(
            "Check-in date: "
        );

    string checkOut =
        readRequired(
            "Check-out date: "
        );

    BookPropertyResponse response =
        check rentalClient->BookProperty({
            guest_id: guestId,
            property_id: propertyId,
            dates: {
                check_in: checkIn,
                check_out: checkOut
            }
        });

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    io:println(
        "Success        : ",
        response.success
    );

    io:println(
        "Message        : ",
        response.message
    );

    io:println(
        "Cart ID        : ",
        response.cart_id
    );

    io:println(
        "Estimated cost : N$",
        response.estimated_cost
    );

    if response.success && response.cart_id != "" {

        session.cartIds.push(
            response.cart_id
        );

        session.lastCartId =
            response.cart_id;
    }

    return;
}


// ============================================================================
// OPTION 7
// CONFIRM BOOKING
//
// Rubric:
//      confirm_booking
//      Re-check availability
//      Calculate/finalize total cost
// ============================================================================

function confirmBookingMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("7 - CONFIRM BOOKING");
    io:println("============================================================");

    string guestId =
        readRequired(
            "Guest ID: "
        );

    string cartId =
        readCartId(session);

    ConfirmBookingResponse response =
        check rentalClient->ConfirmBooking({
            guest_id: guestId,
            cart_id: cartId
        });

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    io:println(
        "Success : ",
        response.success
    );

    io:println(
        "Message : ",
        response.message
    );

    if response.success {

        io:println();
        io:println("Confirmed booking:");
        io:println(
            "  Booking ID  : ",
            response.booking.booking_id
        );

        io:println(
            "  Property ID : ",
            response.booking.property_id
        );

        io:println(
            "  Guest ID    : ",
            response.booking.guest_id
        );

        io:println(
            "  Dates       : ",
            response.booking.dates
        );

        io:println(
            "  Total cost  : N$",
            response.booking.total_cost
        );

        io:println(
            "  Status      : ",
            response.booking.status
        );

        if response.booking.booking_id != "" {

            session.bookingIds.push(
                response.booking.booking_id
            );

            session.lastBookingId =
                response.booking.booking_id;
        }

    } else {

        io:println();
        io:println(
            "Booking was not confirmed."
        );
    }

    return;
}


// ============================================================================
// OPTION 8
// REMOVE PROPERTY
//
// Rubric:
//      remove_property
//      Returns remaining properties in the same region
// ============================================================================

function removePropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("8 - REMOVE PROPERTY");
    io:println("============================================================");

    string propertyId =
        readPropertyId(session);

    RemovePropertyResponse response =
        check rentalClient->RemoveProperty({
            property_id: propertyId
        });

    io:println();
    io:println("---------------- SERVER RESPONSE ----------------");

    io:println(
        "Success : ",
        response.success
    );

    io:println(
        "Message : ",
        response.message
    );

    io:println();
    io:println(
        "Remaining properties returned by server:"
    );

    if response.remaining_properties.length() == 0 {

        io:println(
            "  No remaining properties."
        );

    } else {

        foreach Property property
            in response.remaining_properties {

            io:println(
                "  -> ",
                property
            );
        }
    }

    return;
}


// ============================================================================
// OPTION 9
// COMPLETE END-TO-END DEMONSTRATION
//
// This reproduces your original one-shot main.bal demonstration.
// ============================================================================

function runEndToEndDemo(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {

    io:println("============================================================");
    io:println("9 - COMPLETE END-TO-END DEMONSTRATION");
    io:println("============================================================");

    io:println();
    io:println(
        "NOTE: This scenario uses fixed demo IDs such as HOST-001"
    );

    io:println(
        "and GUEST-001. A fresh server session is recommended."
    );

    io:println();

    // =======================================================================
    // STEP 1
    // CLIENT-SIDE STREAMING - CREATE USERS
    // =======================================================================

    io:println("STEP 1: Creating HOST-001 and GUEST-001...");

    CreateUsersStreamingClient userStream =
        check rentalClient->CreateUsers();

    check userStream->sendUser({
        user_id: "HOST-001",
        name: "Katrina Host",
        email: "kat@example.na",
        role: HOST,
        region: "Erongo"
    });

    check userStream->sendUser({
        user_id: "GUEST-001",
        name: "Jonas Guest",
        email: "jonas@example.na",
        role: GUEST,
        region: ""
    });

    check userStream->complete();

    CreateUsersResponse? userResponse =
        check userStream->receiveCreateUsersResponse();

    io:println(
        "[create_users] ",
        userResponse
    );

    session.submittedUserIds.push(
        "HOST-001"
    );

    session.submittedUserIds.push(
        "GUEST-001"
    );


    // =======================================================================
    // STEP 2
    // ADD PROPERTY #1
    // =======================================================================

    io:println();
    io:println("STEP 2: Adding Dune View Apartment...");

    AddPropertyResponse p1 =
        check rentalClient->AddProperty({
            host_id: "HOST-001",
            name: "Dune View Apartment",
            location: "Swakopmund, Erongo",
            region: "Erongo",
            property_type: "Apartment",
            price_per_night: 850.0,
            description: "Two-bedroom with ocean view."
        });

    io:println(
        "[add_property #1] ",
        p1
    );

    if p1.property_id != "" {
        session.propertyIds.push(
            p1.property_id
        );

        session.lastPropertyId =
            p1.property_id;
    }


    // =======================================================================
    // STEP 3
    // ADD PROPERTY #2
    // =======================================================================

    io:println();
    io:println("STEP 3: Adding Kalahari Lodge...");

    AddPropertyResponse p2 =
        check rentalClient->AddProperty({
            host_id: "HOST-001",
            name: "Kalahari Lodge",
            location: "Windhoek, Khomas",
            region: "Khomas",
            property_type: "Lodge",
            price_per_night: 1200.0,
            description: "Desert lodge with pool."
        });

    io:println(
        "[add_property #2] ",
        p2
    );

    if p2.property_id != "" {
        session.propertyIds.push(
            p2.property_id
        );

        session.lastPropertyId =
            p2.property_id;
    }


    // =======================================================================
    // STEP 4
    // SERVER-SIDE STREAMING - ALL AVAILABLE
    // =======================================================================

    io:println();
    io:println("STEP 4: Listing all available properties...");

    stream<Property, grpc:Error?> all =
        check rentalClient->ListAvailableProperties({});

    check drain(all);


    // =======================================================================
    // STEP 5
    // SERVER-SIDE STREAMING WITH FILTER
    // =======================================================================

    io:println();
    io:println(
        "STEP 5: Listing Erongo properties <= N$1000/night..."
    );

    stream<Property, grpc:Error?> filtered =
        check rentalClient->ListAvailableProperties({
            location_filter: "Erongo",
            min_price: 0.0,
            max_price: 1000.0
        });

    check drain(filtered);


    // =======================================================================
    // STEP 6
    // SEARCH PROPERTY
    // =======================================================================

    io:println();
    io:println(
        "STEP 6: Searching for first property..."
    );

    SearchPropertyResponse search =
        check rentalClient->SearchProperty({
            property_id: p1.property_id
        });

    io:println(
        "[search_property] ",
        search
    );


    // =======================================================================
    // STEP 7
    // UPDATE PROPERTY
    // =======================================================================

    io:println();
    io:println(
        "STEP 7: Updating first property price to N$900..."
    );

    UpdatePropertyResponse updated =
        check rentalClient->UpdateProperty({
            property_id: p1.property_id,
            price_per_night: 900.0
        });

    io:println(
        "[update_property] ",
        updated
    );


    // =======================================================================
    // STEP 8
    // ADD BOOKING TO CART
    // =======================================================================

    io:println();
    io:println(
        "STEP 8: Adding booking to cart..."
    );

    BookPropertyResponse cart =
        check rentalClient->BookProperty({
            guest_id: "GUEST-001",
            property_id: p1.property_id,
            dates: {
                check_in: "2026-10-01",
                check_out: "2026-10-05"
            }
        });

    io:println(
        "[book_property] ",
        cart
    );

    if cart.cart_id != "" {

        session.cartIds.push(
            cart.cart_id
        );

        session.lastCartId =
            cart.cart_id;
    }


    // =======================================================================
    // STEP 9
    // CONFIRM BOOKING
    // =======================================================================

    io:println();
    io:println(
        "STEP 9: Confirming booking..."
    );

    ConfirmBookingResponse confirmed =
        check rentalClient->ConfirmBooking({
            guest_id: "GUEST-001",
            cart_id: cart.cart_id
        });

    io:println(
        "[confirm_booking] ",
        confirmed
    );

    if confirmed.success &&
        confirmed.booking.booking_id != "" {

        session.bookingIds.push(
            confirmed.booking.booking_id
        );

        session.lastBookingId =
            confirmed.booking.booking_id;
    }


    // =======================================================================
    // STEP 10
    // ATTEMPT OVERLAPPING BOOKING
    // =======================================================================

    io:println();
    io:println(
        "STEP 10: Testing overlapping booking..."
    );

    BookPropertyResponse overlappingCart =
        check rentalClient->BookProperty({
            guest_id: "GUEST-001",
            property_id: p1.property_id,
            dates: {
                check_in: "2026-10-03",
                check_out: "2026-10-07"
            }
        });

    ConfirmBookingResponse overlappingConfirmation =
        check rentalClient->ConfirmBooking({
            guest_id: "GUEST-001",
            cart_id: overlappingCart.cart_id
        });

    io:println(
        "[confirm_booking overlap - EXPECT FAILURE] ",
        overlappingConfirmation
    );


    // =======================================================================
    // STEP 11
    // REMOVE SECOND PROPERTY
    // =======================================================================

    io:println();
    io:println(
        "STEP 11: Removing second property..."
    );

    RemovePropertyResponse removed =
        check rentalClient->RemoveProperty({
            property_id: p2.property_id
        });

    io:println(
        "[remove_property] ",
        removed
    );


    io:println();
    io:println("============================================================");
    io:println("END-TO-END DEMONSTRATION COMPLETE");
    io:println("============================================================");

    return;
}


// ============================================================================
// OPTION 10
// DISPLAY CLIENT-SIDE IN-MEMORY SESSION STATE
// ============================================================================

function showSessionState(
    SessionState session
) {

    io:println("============================================================");
    io:println("10 - CLI IN-MEMORY SESSION STATE");
    io:println("============================================================");

    io:println();
    io:println(
        "This represents IDs remembered by this CLI process."
    );

    io:println(
        "It is separate from the server's private in-memory state."
    );


    // USERS
    io:println();
    io:println(
        "Submitted User IDs (",
        session.submittedUserIds.length(),
        "):"
    );

    printStringList(
        session.submittedUserIds
    );


    // PROPERTIES
    io:println();
    io:println(
        "Property IDs (",
        session.propertyIds.length(),
        "):"
    );

    printStringList(
        session.propertyIds
    );


    // CARTS
    io:println();
    io:println(
        "Cart IDs (",
        session.cartIds.length(),
        "):"
    );

    printStringList(
        session.cartIds
    );


    // BOOKINGS
    io:println();
    io:println(
        "Booking IDs (",
        session.bookingIds.length(),
        "):"
    );

    printStringList(
        session.bookingIds
    );


    io:println();
    io:println("---------------- LAST ACTIVE IDs ----------------");

    io:println(
        "Last property ID : ",
        session.lastPropertyId == ""
            ? "<none>"
            : session.lastPropertyId
    );

    io:println(
        "Last cart ID     : ",
        session.lastCartId == ""
            ? "<none>"
            : session.lastCartId
    );

    io:println(
        "Last booking ID  : ",
        session.lastBookingId == ""
            ? "<none>"
            : session.lastBookingId
    );
}


// ============================================================================
// STREAM HELPERS
// ============================================================================

// Drain server-streaming Property responses.
function drain(
    stream<Property, grpc:Error?> propertyStream
) returns error? {

    error? streamError =
        from Property property in propertyStream
        do {
            io:println(
                "   -> ",
                property
            );
        };

    return streamError;
}


// Same as drain(), but also counts the received properties.
function drainAndCount(
    stream<Property, grpc:Error?> propertyStream
) returns int|error {

    int count = 0;

    error? streamError =
        from Property property in propertyStream
        do {
            count += 1;

            io:println(
                "   -> ",
                property
            );
        };

    if streamError is error {
        return streamError;
    }

    return count;
}


// ============================================================================
// CLI INPUT HELPERS
// ============================================================================

// Require a non-empty string.
function readRequired(
    string prompt
) returns string {

    while true {

        string value =
            io:readln(prompt).trim();

        if value != "" {
            return value;
        }

        io:println(
            "A value is required."
        );
    }
}


// Read an integer with a default value.
function readPositiveIntWithDefault(
    string prompt,
    int defaultValue
) returns int {

    while true {

        string input =
            io:readln(prompt).trim();

        if input == "" {
            return defaultValue;
        }

        int|error parsed =
            int:fromString(input);

        if parsed is int {

            if parsed > 0 {
                return parsed;
            }

            io:println(
                "Please enter a number greater than zero."
            );

        } else {

            io:println(
                "Please enter a valid whole number."
            );
        }
    }
}


// Require a positive floating-point number.
function readPositiveFloat(
    string prompt
) returns float {

    while true {

        string input =
            io:readln(prompt).trim();

        float|error parsed =
            float:fromString(input);

        if parsed is float {

            if parsed > 0.0 {
                return parsed;
            }

            io:println(
                "Value must be greater than zero."
            );

        } else {

            io:println(
                "Please enter a valid number."
            );
        }
    }
}


// Optional float with a default.
function readOptionalFloat(
    string prompt,
    float defaultValue
) returns float {

    while true {

        string input =
            io:readln(prompt).trim();

        if input == "" {
            return defaultValue;
        }

        float|error parsed =
            float:fromString(input);

        if parsed is float {

            if parsed >= 0.0 {
                return parsed;
            }

            io:println(
                "Value cannot be negative."
            );

        } else {

            io:println(
                "Please enter a valid number."
            );
        }
    }
}


// ============================================================================
// ROLE INPUT
// ============================================================================

function readUserRole()
    returns UserRole {

    while true {

        io:println();
        io:println("User role:");
        io:println("  1. HOST");
        io:println("  2. GUEST");

        string role =
            io:readln(
                "Select role [1-2]: "
            ).trim();

        if role == "1" {
            return HOST;
        }

        if role == "2" {
            return GUEST;
        }

        io:println(
            "Invalid role."
        );
    }
}


// ============================================================================
// PROPERTY STATUS INPUT
// ============================================================================

function readPropertyStatus()
    returns PropertyStatus {

    while true {

        io:println();
        io:println("Property status:");
        io:println("  1. AVAILABLE");
        io:println("  2. BOOKED");
        io:println("  3. UNDER_MAINTENANCE");
        io:println("  4. DELISTED");

        string status =
            io:readln(
                "Select status [1-4]: "
            ).trim();

        if status == "1" {
            return AVAILABLE;
        }

        if status == "2" {
            return BOOKED;
        }

        if status == "3" {
            return UNDER_MAINTENANCE;
        }

        if status == "4" {
            return DELISTED;
        }

        io:println(
            "Invalid status."
        );
    }
}


// ============================================================================
// PROPERTY-ID HELPER
// ============================================================================

function readPropertyId(
    SessionState session
) returns string {

    if session.lastPropertyId != "" {

        io:println(
            "Last property ID: ",
            session.lastPropertyId
        );

        string propertyId =
            io:readln(
                "Property ID [ENTER = last property]: "
            ).trim();

        if propertyId == "" {
            return session.lastPropertyId;
        }

        return propertyId;
    }

    return readRequired(
        "Property ID: "
    );
}


// ============================================================================
// CART-ID HELPER
// ============================================================================

function readCartId(
    SessionState session
) returns string {

    if session.lastCartId != "" {

        io:println(
            "Last cart ID: ",
            session.lastCartId
        );

        string cartId =
            io:readln(
                "Cart ID [ENTER = last cart]: "
            ).trim();

        if cartId == "" {
            return session.lastCartId;
        }

        return cartId;
    }

    return readRequired(
        "Cart ID: "
    );
}


// ============================================================================
// ARRAY DISPLAY HELPER
// ============================================================================

function printStringList(
    string[] values
) {

    if values.length() == 0 {

        io:println(
            "  <none>"
        );

        return;
    }

    foreach string value in values {

        io:println(
            "  - ",
            value
        );
    }
}

