import ballerina/io;
import ballerina/grpc;


// =============================================================================
// CLIENT-SIDE CONVENIENCE STATE
// =============================================================================
//
// IMPORTANT:
//
// This object is NOT the application's persistent storage.
//
// Persistent data lives in:
//
//      PostgreSQL
//          ↑
//      rental_service
//          ↑ gRPC
//      this CLI client
//
// This object only remembers IDs during the current CLI session so that the
// user does not have to repeatedly type recently generated IDs.
//
// If this CLI is restarted, persisted users/properties/bookings can still be
// retrieved using the List/Search RPC operations.
// =============================================================================

class SessionState {

    public string[] generatedUserIds = [];
    public string[] propertyIds = [];
    public string[] cartIds = [];
    public string[] bookingIds = [];

    public string lastUserId = "";
    public string lastHostId = "";
    public string lastGuestId = "";

    public string lastPropertyId = "";
    public string lastCartId = "";
    public string lastBookingId = "";
}


// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

public function main() returns error? {

    io:println();
    io:println("============================================================");
    io:println("       NAMIBIA RENTAL PLATFORM - gRPC CLI CLIENT");
    io:println("============================================================");
    io:println();


    // -------------------------------------------------------------------------
    // Connect to the Ballerina gRPC rental service.
    //
    // The CLI does NOT connect directly to PostgreSQL.
    // -------------------------------------------------------------------------

    RentalServiceClient rentalClient =
        check new ("http://localhost:9090");


    SessionState session = new ();


    io:println(
        "Connected to RentalService at http://localhost:9090"
    );

    io:println(
        "Persistence: rental_service -> PostgreSQL"
    );

    io:println();


    while true {

        printMenu();


        string choice =
            io:readln(
                "Select an option [0-16]: "
            ).trim();


        io:println();


        if choice == "0" {

            io:println(
                "Closing Rental Platform CLI..."
            );

            io:println(
                "Persistent records remain in PostgreSQL."
            );

            io:println(
                "Goodbye."
            );

            break;
        }


        error? operationResult =
            runMenuChoice(
                choice,
                rentalClient,
                session
            );


        if operationResult is error {

            io:println();

            io:println(
                "------------------------------------------------------------"
            );

            io:println(
                "OPERATION FAILED"
            );

            io:println(
                "------------------------------------------------------------"
            );

            io:println(
                operationResult
            );
        }


        io:println();

        _ = io:readln(
            "Press ENTER to return to the menu..."
        );

        io:println();
    }


    return;
}


// =============================================================================
// MENU
// =============================================================================

function printMenu() {

    io:println(
        "============================================================"
    );

    io:println(
        "                    RENTAL SERVICE MENU"
    );

    io:println(
        "============================================================"
    );


    io:println(
        "  1. Create users"
    );

    io:println(
        "     Client-side streaming + server-generated IDs"
    );

    io:println();


    io:println(
        "  2. Add property"
    );

    io:println(
        "     Simple RPC + generated property ID"
    );

    io:println();


    io:println(
        "  3. List available properties"
    );

    io:println(
        "     Server-side streaming + filters"
    );

    io:println();


    io:println(
        "  4. Search property"
    );

    io:println(
        "     Search persisted property"
    );

    io:println();


    io:println(
        "  5. Update property"
    );

    io:println(
        "     Persist price/status/description changes"
    );

    io:println();


    io:println(
        "  6. Book property"
    );

    io:println(
        "     Creates persistent-backed cart request"
    );

    io:println();


    io:println(
        "  7. Confirm booking"
    );

    io:println(
        "     Creates persisted booking"
    );

    io:println();


    io:println(
        "  8. Remove property"
    );

    io:println(
        "     Remove through rental service"
    );

    io:println();


    io:println(
        "  9. Run complete end-to-end demonstration"
    );

    io:println(
        "     Uses SERVER-GENERATED IDs"
    );

    io:println();


    io:println(
        " 10. Inspect CLI convenience state"
    );

    io:println(
        "     Not database storage"
    );

    io:println();


    io:println(
        " 11. View users"
    );

    io:println(
        "     All / Hosts / Guests"
    );

    io:println();


    io:println(
        " 12. Search user"
    );

    io:println(
        "     Search persisted user by ID"
    );

    io:println();


    io:println(
        " 13. View active bookings"
    );

    io:println(
        "     Server-side streaming"
    );

    io:println();


    io:println(
        " 14. Search booking"
    );

    io:println(
        "     Searches active + removed records"
    );

    io:println();


    io:println(
        " 15. Remove / cancel booking"
    );

    io:println(
        "     Archives booking before removal"
    );

    io:println();


    io:println(
        " 16. View removed booking history"
    );

    io:println(
        "     Persistent booking archive"
    );


    io:println();

    io:println(
        "------------------------------------------------------------"
    );

    io:println(
        "                        0. Exit"
    );

    io:println(
        "------------------------------------------------------------"
    );

    io:println(
        "============================================================"
    );
}


// =============================================================================
// MENU ROUTER
// =============================================================================

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

        showSessionState(
            session
        );

        return;


    } else if choice == "11" {

        return listUsersMenu(
            rentalClient
        );


    } else if choice == "12" {

        return searchUserMenu(
            rentalClient,
            session
        );


    } else if choice == "13" {

        return listBookingsMenu(
            rentalClient
        );


    } else if choice == "14" {

        return searchBookingMenu(
            rentalClient,
            session
        );


    } else if choice == "15" {

        return removeBookingMenu(
            rentalClient,
            session
        );


    } else if choice == "16" {

        return listRemovedBookingsMenu(
            rentalClient
        );


    } else {

        io:println(
            "Invalid option."
        );

        io:println(
            "Please select a value between 0 and 16."
        );

        return;
    }
}


// =============================================================================
// OPTION 1 - CREATE USERS
// =============================================================================
//
// Client-side streaming.
//
// IMPORTANT:
// User IDs are NOT supplied by the client.
//
// The client sends:
//
//      user_id: ""
//
// PostgreSQL/Ballerina generates:
//
//      USR-0001
//      USR-0002
//      ...
//
// The generated users are returned through:
//
//      CreateUsersResponse.created_users
//
// =============================================================================

function createUsersMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "1 - CREATE USERS"
    );

    io:println(
        "Client-side streaming + database persistence"
    );

    io:println(
        "============================================================"
    );


    int userCount =
        readPositiveIntWithDefault(
            "How many users do you want to create? [2]: ",
            2
        );


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


        // ---------------------------------------------------------------------
        // No User ID prompt.
        // The database/service generates it.
        // ---------------------------------------------------------------------

        string name =
            readRequired(
                "Name: "
            );


        string email =
            readRequired(
                "Email: "
            );


        UserRole role =
            readUserRole();


        string region =
            io:readln(
                "Region (optional): "
            ).trim();


        check userStream->sendUser({
            user_id: "",
            name: name,
            email: email,
            role: role,
            region: region
        });


        io:println(
            "User submitted for server-side ID generation."
        );


        index += 1;
    }


    // Signal the end of client-side streaming.

    check userStream->complete();


    CreateUsersResponse? response =
        check userStream->receiveCreateUsersResponse();


    io:println();

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    if response is CreateUsersResponse {

        io:println(
            "Created count : ",
            response.created_count
        );


        io:println(
            "Message       : ",
            response.message
        );


        io:println();


        if response.created_users.length() == 0 {

            io:println(
                "No generated users were returned."
            );

        } else {

            io:println(
                "Generated users:"
            );


            foreach User createdUser
                in response.created_users {

                printUser(
                    createdUser
                );


                rememberGeneratedUser(
                    session,
                    createdUser
                );
            }
        }


    } else {

        io:println(
            "The stream completed without a response payload."
        );
    }


    return;
}


// =============================================================================
// OPTION 2 - ADD PROPERTY
// =============================================================================

function addPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "2 - ADD PROPERTY"
    );

    io:println(
        "Simple RPC + persistent PostgreSQL insert"
    );

    io:println(
        "============================================================"
    );


    io:println();

    io:println(
        "Registered HOST users:"
    );


    // Display persisted hosts before asking the user which host owns
    // the property.

    stream<User, grpc:Error?> hostStream =
        check rentalClient->ListUsers({
            role_filter: HOST
        });


    check drainUsers(
        hostStream
    );


    io:println();


    string hostId =
        readHostId(
            session
        );


    string name =
        readRequired(
            "Property name: "
        );


    string location =
        readRequired(
            "Location: "
        );


    string region =
        readRequired(
            "Region: "
        );


    string propertyType =
        readRequired(
            "Property type: "
        );


    float price =
        readPositiveFloat(
            "Price per night (N$): "
        );


    string description =
        readRequired(
            "Description: "
        );


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

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    io:println(
        "Success     : ",
        response.success
    );


    io:println(
        "Message     : ",
        response.message
    );


    io:println(
        "Property ID : ",
        response.property_id
    );


    if response.success &&
        response.property_id != "" {

        session.propertyIds.push(
            response.property_id
        );

        session.lastPropertyId =
            response.property_id;
    }


    return;
}


// =============================================================================
// OPTION 3 - LIST AVAILABLE PROPERTIES
// =============================================================================

function listPropertiesMenu(
    RentalServiceClient rentalClient
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "3 - LIST AVAILABLE PROPERTIES"
    );

    io:println(
        "Server-side streaming from persisted records"
    );

    io:println(
        "============================================================"
    );


    string useFilters =
        io:readln(
            "Apply filters? [y/N]: "
        ).trim();


    stream<Property, grpc:Error?> propertyStream;


    if useFilters == "y" ||
        useFilters == "Y" ||
        useFilters == "yes" ||
        useFilters == "YES" {


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

        propertyStream =
            check rentalClient->ListAvailableProperties({});
    }


    io:println();

    io:println(
        "---------------- STREAM RESULTS ----------------"
    );


    int count =
        check drainAndCountProperties(
            propertyStream
        );


    io:println();

    io:println(
        "Total available properties: ",
        count
    );


    return;
}


// =============================================================================
// OPTION 4 - SEARCH PROPERTY
// =============================================================================

function searchPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "4 - SEARCH PROPERTY"
    );

    io:println(
        "============================================================"
    );


    string propertyId =
        readPropertyId(
            session
        );


    SearchPropertyResponse response =
        check rentalClient->SearchProperty({
            property_id: propertyId
        });


    io:println();

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    io:println(
        "Available : ",
        response.available
    );


    io:println(
        "Message   : ",
        response.message
    );


    if response.property.property_id != "" {

        printProperty(
            response.property
        );
    }


    return;
}


// =============================================================================
// OPTION 5 - UPDATE PROPERTY
// =============================================================================

function updatePropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "5 - UPDATE PROPERTY"
    );

    io:println(
        "Changes are persisted through rental_service"
    );

    io:println(
        "============================================================"
    );


    string propertyId =
        readPropertyId(
            session
        );


    io:println();

    io:println(
        "What would you like to update?"
    );

    io:println(
        "  1. Price"
    );

    io:println(
        "  2. Status"
    );

    io:println(
        "  3. Description"
    );


    string updateChoice =
        io:readln(
            "Select update type [1-3]: "
        ).trim();


    UpdatePropertyResponse response;


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


    } else if updateChoice == "2" {

        PropertyStatus newStatus =
            readPropertyStatus();


        response =
            check rentalClient->UpdateProperty({
                property_id: propertyId,
                status: newStatus
            });


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

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    io:println(
        "Success : ",
        response.success
    );


    io:println(
        "Message : ",
        response.message
    );


    if response.property.property_id != "" {

        printProperty(
            response.property
        );
    }


    return;
}


// =============================================================================
// OPTION 6 - BOOK PROPERTY / ADD TO CART
// =============================================================================

function bookPropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "6 - BOOK PROPERTY"
    );

    io:println(
        "Creates a persisted-backed cart request"
    );

    io:println(
        "============================================================"
    );


    io:println();

    io:println(
        "Registered GUEST users:"
    );


    stream<User, grpc:Error?> guestStream =
        check rentalClient->ListUsers({
            role_filter: GUEST
        });


    check drainUsers(
        guestStream
    );


    io:println();

    io:println(
        "Available properties:"
    );


    stream<Property, grpc:Error?> availableStream =
        check rentalClient->ListAvailableProperties({});


    check drainProperties(
        availableStream
    );


    io:println();


    string guestId =
        readGuestId(
            session
        );


    string propertyId =
        readPropertyId(
            session
        );


    io:println();

    io:println(
        "Date format: YYYY-MM-DD"
    );


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

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


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


    if response.success &&
        response.cart_id != "" {

        session.cartIds.push(
            response.cart_id
        );

        session.lastCartId =
            response.cart_id;


        session.lastGuestId =
            guestId;
    }


    return;
}


// =============================================================================
// OPTION 7 - CONFIRM BOOKING
// =============================================================================

function confirmBookingMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "7 - CONFIRM BOOKING"
    );

    io:println(
        "Creates a persistent booking record"
    );

    io:println(
        "============================================================"
    );


    string guestId =
        readGuestId(
            session
        );


    string cartId =
        readCartId(
            session
        );


    ConfirmBookingResponse response =
        check rentalClient->ConfirmBooking({
            guest_id: guestId,
            cart_id: cartId
        });


    io:println();

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    io:println(
        "Success : ",
        response.success
    );


    io:println(
        "Message : ",
        response.message
    );


    if response.success {

        printBooking(
            response.booking
        );


        if response.booking.booking_id != "" {

            session.bookingIds.push(
                response.booking.booking_id
            );

            session.lastBookingId =
                response.booking.booking_id;
        }


    } else {

        io:println(
            "Booking was not confirmed."
        );
    }


    return;
}


// =============================================================================
// OPTION 8 - REMOVE PROPERTY
// =============================================================================

function removePropertyMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "8 - REMOVE PROPERTY"
    );

    io:println(
        "============================================================"
    );


    string propertyId =
        readPropertyId(
            session
        );


    RemovePropertyResponse response =
        check rentalClient->RemoveProperty({
            property_id: propertyId
        });


    io:println();

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


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

            printProperty(
                property
            );
        }
    }


    return;
}


// =============================================================================
// OPTION 9 - COMPLETE END-TO-END DEMONSTRATION
// =============================================================================
//
// This version deliberately does NOT use:
//      HOST-001
//      GUEST-001
//
// The database generates the user IDs and those generated IDs are used for the
// remainder of the demonstration.
// =============================================================================

function runEndToEndDemo(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "9 - COMPLETE END-TO-END DATABASE DEMONSTRATION"
    );

    io:println(
        "============================================================"
    );


    io:println();

    io:println(
        "This demonstration uses server-generated IDs."
    );


    // =========================================================================
    // STEP 1 - CREATE HOST + GUEST
    // =========================================================================

    io:println();

    io:println(
        "STEP 1: Creating demo host and guest..."
    );


    CreateUsersStreamingClient userStream =
        check rentalClient->CreateUsers();


    // Use a changing suffix so repeated demonstrations do not immediately
    // collide on unique email addresses.

    int suffix =
        check int:fromString(
            timeSuffix()
        );


    string hostEmail =
        string `demo.host.${suffix}@example.na`;


    string guestEmail =
        string `demo.guest.${suffix}@example.na`;


    check userStream->sendUser({
        user_id: "",
        name: "Katrina Demo Host",
        email: hostEmail,
        role: HOST,
        region: "Erongo"
    });


    check userStream->sendUser({
        user_id: "",
        name: "Jonas Demo Guest",
        email: guestEmail,
        role: GUEST,
        region: "Khomas"
    });


    check userStream->complete();


    CreateUsersResponse? userResponse =
        check userStream->receiveCreateUsersResponse();


    string hostId = "";
    string guestId = "";


    if userResponse is CreateUsersResponse {

        io:println(
            "[CreateUsers] ",
            userResponse.message
        );


        foreach User generatedUser
            in userResponse.created_users {


            printUser(
                generatedUser
            );


            rememberGeneratedUser(
                session,
                generatedUser
            );


            if generatedUser.role == HOST &&
                hostId == "" {

                hostId =
                    generatedUser.user_id;
            }


            if generatedUser.role == GUEST &&
                guestId == "" {

                guestId =
                    generatedUser.user_id;
            }
        }
    }


    if hostId == "" {

        return error(
            "Demo could not obtain a generated HOST user ID."
        );
    }


    if guestId == "" {

        return error(
            "Demo could not obtain a generated GUEST user ID."
        );
    }


    io:println();

    io:println(
        "Generated HOST ID  : ",
        hostId
    );


    io:println(
        "Generated GUEST ID : ",
        guestId
    );


    // =========================================================================
    // STEP 2 - ADD PROPERTY #1
    // =========================================================================

    io:println();

    io:println(
        "STEP 2: Adding Dune View Apartment..."
    );


    AddPropertyResponse p1 =
        check rentalClient->AddProperty({
            host_id: hostId,
            name: "Dune View Apartment",
            location: "Swakopmund, Erongo",
            region: "Erongo",
            property_type: "Apartment",
            price_per_night: 850.0,
            description: "Two-bedroom with ocean view."
        });


    io:println(
        "[AddProperty #1] ",
        p1
    );


    if !p1.success ||
        p1.property_id == "" {

        return error(
            string `Unable to create demo property: ${p1.message}`
        );
    }


    session.propertyIds.push(
        p1.property_id
    );

    session.lastPropertyId =
        p1.property_id;


    // =========================================================================
    // STEP 3 - ADD PROPERTY #2
    // =========================================================================

    io:println();

    io:println(
        "STEP 3: Adding Kalahari Lodge..."
    );


    AddPropertyResponse p2 =
        check rentalClient->AddProperty({
            host_id: hostId,
            name: "Kalahari Lodge",
            location: "Windhoek, Khomas",
            region: "Khomas",
            property_type: "Lodge",
            price_per_night: 1200.0,
            description: "Desert lodge with pool."
        });


    io:println(
        "[AddProperty #2] ",
        p2
    );


    if p2.success &&
        p2.property_id != "" {

        session.propertyIds.push(
            p2.property_id
        );

        session.lastPropertyId =
            p2.property_id;
    }


    // =========================================================================
    // STEP 4 - LIST ALL AVAILABLE
    // =========================================================================

    io:println();

    io:println(
        "STEP 4: Listing all available properties..."
    );


    stream<Property, grpc:Error?> all =
        check rentalClient->ListAvailableProperties({});


    check drainProperties(
        all
    );


    // =========================================================================
    // STEP 5 - FILTER AVAILABLE
    // =========================================================================

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


    check drainProperties(
        filtered
    );


    // =========================================================================
    // STEP 6 - SEARCH PROPERTY
    // =========================================================================

    io:println();

    io:println(
        "STEP 6: Searching for generated property ID ",
        p1.property_id,
        "..."
    );


    SearchPropertyResponse search =
        check rentalClient->SearchProperty({
            property_id: p1.property_id
        });


    io:println(
        "[SearchProperty] ",
        search
    );


    // =========================================================================
    // STEP 7 - UPDATE PROPERTY
    // =========================================================================

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
        "[UpdateProperty] ",
        updated
    );


    // =========================================================================
    // STEP 8 - BOOK / CART
    // =========================================================================

    io:println();

    io:println(
        "STEP 8: Adding booking request to cart..."
    );


    BookPropertyResponse cart =
        check rentalClient->BookProperty({
            guest_id: guestId,
            property_id: p1.property_id,
            dates: {
                check_in: "2026-10-01",
                check_out: "2026-10-05"
            }
        });


    io:println(
        "[BookProperty] ",
        cart
    );


    if !cart.success ||
        cart.cart_id == "" {

        return error(
            string `Unable to create demo cart item: ${cart.message}`
        );
    }


    session.cartIds.push(
        cart.cart_id
    );

    session.lastCartId =
        cart.cart_id;


    // =========================================================================
    // STEP 9 - CONFIRM BOOKING
    // =========================================================================

    io:println();

    io:println(
        "STEP 9: Confirming booking..."
    );


    ConfirmBookingResponse confirmed =
        check rentalClient->ConfirmBooking({
            guest_id: guestId,
            cart_id: cart.cart_id
        });


    io:println(
        "[ConfirmBooking] ",
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


    // =========================================================================
    // STEP 10 - LIST PERSISTED USERS
    // =========================================================================

    io:println();

    io:println(
        "STEP 10: Listing persisted users..."
    );


    stream<User, grpc:Error?> users =
        check rentalClient->ListUsers({
            role_filter: USER_ROLE_UNSPECIFIED
        });


    check drainUsers(
        users
    );


    // =========================================================================
    // STEP 11 - LIST PERSISTED BOOKINGS
    // =========================================================================

    io:println();

    io:println(
        "STEP 11: Listing persisted active bookings..."
    );


    stream<Booking, grpc:Error?> bookings =
        check rentalClient->ListBookings({});


    check drainBookings(
        bookings
    );


    // =========================================================================
    // STEP 12 - REMOVE SECOND PROPERTY
    // =========================================================================

    if p2.success &&
        p2.property_id != "" {

        io:println();

        io:println(
            "STEP 12: Removing second property..."
        );


        RemovePropertyResponse removed =
            check rentalClient->RemoveProperty({
                property_id: p2.property_id
            });


        io:println(
            "[RemoveProperty] ",
            removed
        );
    }


    io:println();

    io:println(
        "============================================================"
    );

    io:println(
        "END-TO-END DATABASE DEMONSTRATION COMPLETE"
    );

    io:println(
        "============================================================"
    );


    io:println(
        "Stop and restart this CLI, then use options 11 and 13."
    );

    io:println(
        "The generated users/bookings should still exist because they are"
    );

    io:println(
        "stored by rental_service in PostgreSQL."
    );


    return;
}


// =============================================================================
// OPTION 10 - CLIENT CONVENIENCE STATE
// =============================================================================

function showSessionState(
    SessionState session
) {


    io:println(
        "============================================================"
    );

    io:println(
        "10 - CLI CONVENIENCE STATE"
    );

    io:println(
        "============================================================"
    );


    io:println();

    io:println(
        "WARNING:"
    );

    io:println(
        "This is NOT persistent storage."
    );

    io:println(
        "Persistent records live in PostgreSQL behind rental_service."
    );


    io:println();

    io:println(
        "Generated User IDs (",
        session.generatedUserIds.length(),
        "):"
    );

    printStringList(
        session.generatedUserIds
    );


    io:println();

    io:println(
        "Property IDs (",
        session.propertyIds.length(),
        "):"
    );

    printStringList(
        session.propertyIds
    );


    io:println();

    io:println(
        "Cart IDs (",
        session.cartIds.length(),
        "):"
    );

    printStringList(
        session.cartIds
    );


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

    io:println(
        "---------------- LAST ACTIVE IDs ----------------"
    );


    io:println(
        "Last user ID     : ",
        emptyAsNone(
            session.lastUserId
        )
    );


    io:println(
        "Last host ID     : ",
        emptyAsNone(
            session.lastHostId
        )
    );


    io:println(
        "Last guest ID    : ",
        emptyAsNone(
            session.lastGuestId
        )
    );


    io:println(
        "Last property ID : ",
        emptyAsNone(
            session.lastPropertyId
        )
    );


    io:println(
        "Last cart ID     : ",
        emptyAsNone(
            session.lastCartId
        )
    );


    io:println(
        "Last booking ID  : ",
        emptyAsNone(
            session.lastBookingId
        )
    );
}


// =============================================================================
// OPTION 11 - LIST USERS
// =============================================================================

function listUsersMenu(
    RentalServiceClient rentalClient
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "11 - VIEW PERSISTED USERS"
    );

    io:println(
        "============================================================"
    );


    io:println(
        "  1. All users"
    );

    io:println(
        "  2. Hosts only"
    );

    io:println(
        "  3. Guests only"
    );


    string choice =
        io:readln(
            "Select filter [1-3]: "
        ).trim();


    UserRole filter =
        USER_ROLE_UNSPECIFIED;


    if choice == "2" {

        filter = HOST;

    } else if choice == "3" {

        filter = GUEST;

    } else if choice != "1" {

        io:println(
            "Invalid filter."
        );

        return;
    }


    stream<User, grpc:Error?> userStream =
        check rentalClient->ListUsers({
            role_filter: filter
        });


    io:println();

    io:println(
        "---------------- DATABASE USERS ----------------"
    );


    int count =
        check drainAndCountUsers(
            userStream
        );


    io:println();

    io:println(
        "Total users: ",
        count
    );


    return;
}


// =============================================================================
// OPTION 12 - SEARCH USER
// =============================================================================

function searchUserMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "12 - SEARCH USER"
    );

    io:println(
        "============================================================"
    );


    string userId =
        readUserId(
            session
        );


    SearchUserResponse response =
        check rentalClient->SearchUser({
            user_id: userId
        });


    io:println();

    io:println(
        "Found   : ",
        response.found
    );


    io:println(
        "Message : ",
        response.message
    );


    if response.found {

        printUser(
            response.user
        );
    }


    return;
}


// =============================================================================
// OPTION 13 - LIST ACTIVE BOOKINGS
// =============================================================================

function listBookingsMenu(
    RentalServiceClient rentalClient
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "13 - VIEW ACTIVE BOOKINGS"
    );

    io:println(
        "============================================================"
    );


    io:println(
        "Leave filters blank to display all active bookings."
    );


    string guestId =
        io:readln(
            "Guest ID filter: "
        ).trim();


    string propertyId =
        io:readln(
            "Property ID filter: "
        ).trim();


    stream<Booking, grpc:Error?> bookingStream =
        check rentalClient->ListBookings({
            guest_id: guestId,
            property_id: propertyId
        });


    io:println();

    io:println(
        "---------------- ACTIVE BOOKINGS ----------------"
    );


    int count =
        check drainAndCountBookings(
            bookingStream
        );


    io:println();

    io:println(
        "Total active bookings: ",
        count
    );


    return;
}


// =============================================================================
// OPTION 14 - SEARCH BOOKING
// =============================================================================

function searchBookingMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "14 - SEARCH BOOKING"
    );

    io:println(
        "Searches active bookings and removed history"
    );

    io:println(
        "============================================================"
    );


    string bookingId =
        readBookingId(
            session
        );


    SearchBookingResponse response =
        check rentalClient->SearchBooking({
            booking_id: bookingId
        });


    io:println();

    io:println(
        "Found   : ",
        response.found
    );


    io:println(
        "Removed : ",
        response.removed
    );


    io:println(
        "Message : ",
        response.message
    );


    if !response.found {

        return;
    }


    if response.removed {

        io:println();

        io:println(
            "Booking exists in removed-booking history:"
        );


        printRemovedBooking(
            response.removed_booking
        );


    } else {

        io:println();

        io:println(
            "Active booking:"
        );


        printBooking(
            response.booking
        );
    }


    return;
}


// =============================================================================
// OPTION 15 - REMOVE / CANCEL BOOKING
// =============================================================================

function removeBookingMenu(
    RentalServiceClient rentalClient,
    SessionState session
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "15 - REMOVE / CANCEL BOOKING"
    );

    io:println(
        "The booking is archived before active deletion."
    );

    io:println(
        "============================================================"
    );


    string bookingId =
        readBookingId(
            session
        );


    string reason =
        readRequired(
            "Reason for cancellation/removal: "
        );


    RemoveBookingResponse response =
        check rentalClient->RemoveBooking({
            booking_id: bookingId,
            reason: reason
        });


    io:println();

    io:println(
        "---------------- SERVER RESPONSE ----------------"
    );


    io:println(
        "Success : ",
        response.success
    );


    io:println(
        "Message : ",
        response.message
    );


    if response.success {

        printRemovedBooking(
            response.removed_booking
        );
    }


    return;
}


// =============================================================================
// OPTION 16 - LIST REMOVED BOOKING HISTORY
// =============================================================================

function listRemovedBookingsMenu(
    RentalServiceClient rentalClient
) returns error? {


    io:println(
        "============================================================"
    );

    io:println(
        "16 - REMOVED BOOKING HISTORY"
    );

    io:println(
        "============================================================"
    );


    io:println(
        "Leave filters blank to list the complete archive."
    );


    string guestId =
        io:readln(
            "Guest ID filter: "
        ).trim();


    string propertyId =
        io:readln(
            "Property ID filter: "
        ).trim();


    stream<RemovedBooking, grpc:Error?> removedStream =
        check rentalClient->ListRemovedBookings({
            guest_id: guestId,
            property_id: propertyId
        });


    io:println();

    io:println(
        "---------------- REMOVED BOOKINGS ----------------"
    );


    int count =
        check drainAndCountRemovedBookings(
            removedStream
        );


    io:println();

    io:println(
        "Total removed bookings: ",
        count
    );


    return;
}


// =============================================================================
// SESSION HELPER - REMEMBER GENERATED USER
// =============================================================================

function rememberGeneratedUser(
    SessionState session,
    User user
) {


    if user.user_id == "" {

        return;
    }


    session.generatedUserIds.push(
        user.user_id
    );


    session.lastUserId =
        user.user_id;


    if user.role == HOST {

        session.lastHostId =
            user.user_id;
    }


    if user.role == GUEST {

        session.lastGuestId =
            user.user_id;
    }
}


// =============================================================================
// STREAM HELPERS - PROPERTIES
// =============================================================================

function drainProperties(
    stream<Property, grpc:Error?> propertyStream
) returns error? {


    error? streamError =
        from Property property
        in propertyStream

        do {

            printProperty(
                property
            );
        };


    return streamError;
}


function drainAndCountProperties(
    stream<Property, grpc:Error?> propertyStream
) returns int|error {


    int count = 0;


    error? streamError =
        from Property property
        in propertyStream

        do {

            count += 1;

            printProperty(
                property
            );
        };


    if streamError is error {

        return streamError;
    }


    return count;
}


// =============================================================================
// STREAM HELPERS - USERS
// =============================================================================

function drainUsers(
    stream<User, grpc:Error?> userStream
) returns error? {


    error? streamError =
        from User user
        in userStream

        do {

            printUser(
                user
            );
        };


    return streamError;
}


function drainAndCountUsers(
    stream<User, grpc:Error?> userStream
) returns int|error {


    int count = 0;


    error? streamError =
        from User user
        in userStream

        do {

            count += 1;

            printUser(
                user
            );
        };


    if streamError is error {

        return streamError;
    }


    return count;
}


// =============================================================================
// STREAM HELPERS - ACTIVE BOOKINGS
// =============================================================================

function drainBookings(
    stream<Booking, grpc:Error?> bookingStream
) returns error? {


    error? streamError =
        from Booking booking
        in bookingStream

        do {

            printBooking(
                booking
            );
        };


    return streamError;
}


function drainAndCountBookings(
    stream<Booking, grpc:Error?> bookingStream
) returns int|error {


    int count = 0;


    error? streamError =
        from Booking booking
        in bookingStream

        do {

            count += 1;

            printBooking(
                booking
            );
        };


    if streamError is error {

        return streamError;
    }


    return count;
}


// =============================================================================
// STREAM HELPERS - REMOVED BOOKINGS
// =============================================================================

function drainAndCountRemovedBookings(
    stream<RemovedBooking, grpc:Error?> removedStream
) returns int|error {


    int count = 0;


    error? streamError =
        from RemovedBooking removedBooking
        in removedStream

        do {

            count += 1;

            printRemovedBooking(
                removedBooking
            );
        };


    if streamError is error {

        return streamError;
    }


    return count;
}


// =============================================================================
// DISPLAY HELPERS
// =============================================================================

function printUser(
    User user
) {


    io:println(
        "------------------------------------------------------------"
    );


    io:println(
        "User ID : ",
        user.user_id
    );


    io:println(
        "Name    : ",
        user.name
    );


    io:println(
        "Email   : ",
        user.email
    );


    io:println(
        "Role    : ",
        user.role
    );


    io:println(
        "Region  : ",
        user.region == ""
            ? "<not specified>"
            : user.region
    );
}


function printProperty(
    Property property
) {


    io:println(
        "------------------------------------------------------------"
    );


    io:println(
        "Property ID : ",
        property.property_id
    );


    io:println(
        "Name        : ",
        property.name
    );


    io:println(
        "Host ID     : ",
        property.host_id
    );


    io:println(
        "Location    : ",
        property.location
    );


    io:println(
        "Region      : ",
        property.region
    );


    io:println(
        "Type        : ",
        property.property_type
    );


    io:println(
        "Price       : N$",
        property.price_per_night
    );


    io:println(
        "Status      : ",
        property.status
    );


    io:println(
        "Description : ",
        property.description
    );
}


function printBooking(
    Booking booking
) {


    io:println(
        "------------------------------------------------------------"
    );


    io:println(
        "Booking ID  : ",
        booking.booking_id
    );


    io:println(
        "Property ID : ",
        booking.property_id
    );


    io:println(
        "Guest ID    : ",
        booking.guest_id
    );


    io:println(
        "Check-in    : ",
        booking.dates.check_in
    );


    io:println(
        "Check-out   : ",
        booking.dates.check_out
    );


    io:println(
        "Total       : N$",
        booking.total_cost
    );


    io:println(
        "Status      : ",
        booking.status
    );
}


function printRemovedBooking(
    RemovedBooking removedBooking
) {


    printBooking(
        removedBooking.booking
    );


    io:println(
        "Removal reason : ",
        removedBooking.reason
    );


    io:println(
        "Removed at     : ",
        removedBooking.removed_at
    );
}


// =============================================================================
// INPUT HELPERS
// =============================================================================

function readRequired(
    string prompt
) returns string {


    while true {

        string value =
            io:readln(
                prompt
            ).trim();


        if value != "" {

            return value;
        }


        io:println(
            "A value is required."
        );
    }
}


function readPositiveIntWithDefault(
    string prompt,
    int defaultValue
) returns int {


    while true {

        string input =
            io:readln(
                prompt
            ).trim();


        if input == "" {

            return defaultValue;
        }


        int|error parsed =
            int:fromString(
                input
            );


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


function readPositiveFloat(
    string prompt
) returns float {


    while true {

        string input =
            io:readln(
                prompt
            ).trim();


        float|error parsed =
            float:fromString(
                input
            );


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


function readOptionalFloat(
    string prompt,
    float defaultValue
) returns float {


    while true {

        string input =
            io:readln(
                prompt
            ).trim();


        if input == "" {

            return defaultValue;
        }


        float|error parsed =
            float:fromString(
                input
            );


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


// =============================================================================
// ROLE INPUT
// =============================================================================

function readUserRole()
    returns UserRole {


    while true {

        io:println();

        io:println(
            "User role:"
        );

        io:println(
            "  1. HOST"
        );

        io:println(
            "  2. GUEST"
        );


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


// =============================================================================
// PROPERTY STATUS INPUT
// =============================================================================

function readPropertyStatus()
    returns PropertyStatus {


    while true {

        io:println();

        io:println(
            "Property status:"
        );


        io:println(
            "  1. AVAILABLE"
        );


        io:println(
            "  2. BOOKED"
        );


        io:println(
            "  3. UNDER_MAINTENANCE"
        );


        io:println(
            "  4. DELISTED"
        );


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


// =============================================================================
// ID HELPERS
// =============================================================================

function readUserId(
    SessionState session
) returns string {


    if session.lastUserId != "" {

        io:println(
            "Last user ID: ",
            session.lastUserId
        );


        string value =
            io:readln(
                "User ID [ENTER = last user]: "
            ).trim();


        if value == "" {

            return session.lastUserId;
        }


        return value;
    }


    return readRequired(
        "User ID: "
    );
}


function readHostId(
    SessionState session
) returns string {


    if session.lastHostId != "" {

        io:println(
            "Last generated host ID: ",
            session.lastHostId
        );


        string value =
            io:readln(
                "Host ID [ENTER = last host]: "
            ).trim();


        if value == "" {

            return session.lastHostId;
        }


        return value;
    }


    return readRequired(
        "Host ID: "
    );
}


function readGuestId(
    SessionState session
) returns string {


    if session.lastGuestId != "" {

        io:println(
            "Last generated guest ID: ",
            session.lastGuestId
        );


        string value =
            io:readln(
                "Guest ID [ENTER = last guest]: "
            ).trim();


        if value == "" {

            return session.lastGuestId;
        }


        return value;
    }


    return readRequired(
        "Guest ID: "
    );
}


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


function readBookingId(
    SessionState session
) returns string {


    if session.lastBookingId != "" {

        io:println(
            "Last booking ID: ",
            session.lastBookingId
        );


        string bookingId =
            io:readln(
                "Booking ID [ENTER = last booking]: "
            ).trim();


        if bookingId == "" {

            return session.lastBookingId;
        }


        return bookingId;
    }


    return readRequired(
        "Booking ID: "
    );
}


// =============================================================================
// ARRAY DISPLAY
// =============================================================================

function printStringList(
    string[] values
) {


    if values.length() == 0 {

        io:println(
            "  <none>"
        );

        return;
    }


    foreach string value
        in values {

        io:println(
            "  - ",
            value
        );
    }
}


// =============================================================================
// SMALL DISPLAY HELPERS
// =============================================================================

function emptyAsNone(
    string value
) returns string {


    return value == ""
        ? "<none>"
        : value;
}


// =============================================================================
// DEMO EMAIL SUFFIX
// =============================================================================
//
// We only need a reasonably changing suffix so that running the end-to-end
// demonstration repeatedly does not use the exact same email addresses.
//
// =============================================================================

function timeSuffix()
    returns string {


    // Keeping this dependency-free and simple for the assignment.
    //
    // The operator can still run the demo repeatedly by restarting the client;
    // a compact pseudo-unique value based on current CLI input is unnecessary
    // for the normal menu operations.
    //
    // This value can be manually changed if duplicate demo emails already
    // exist.

    string custom =
        io:readln(
            "Enter a short demo suffix [e.g. 001]: "
        ).trim();


    if custom == "" {

        return "001";
    }


    return custom;
}