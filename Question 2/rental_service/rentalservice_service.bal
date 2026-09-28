import ballerina/grpc;


// ============================================================================
// gRPC LISTENER
// ============================================================================

listener grpc:Listener ep = new (9090);


// ============================================================================
// RENTAL SERVICE
// ============================================================================

@grpc:Descriptor {
    value: RENTAL_DESC
}
service "RentalService" on ep {


    // ========================================================================
    // PROPERTY MANAGEMENT - SIMPLE RPCs
    // ========================================================================


    // ------------------------------------------------------------------------
    // Add Property
    // ------------------------------------------------------------------------

    remote function AddProperty(
        AddPropertyRequest value
    ) returns AddPropertyResponse|error {

        return addProperty(value);
    }


    // ------------------------------------------------------------------------
    // Update Property
    // ------------------------------------------------------------------------

    remote function UpdateProperty(
        UpdatePropertyRequest value
    ) returns UpdatePropertyResponse|error {

        return updateProperty(value);
    }


    // ------------------------------------------------------------------------
    // Remove Property
    // ------------------------------------------------------------------------

    remote function RemoveProperty(
        RemovePropertyRequest value
    ) returns RemovePropertyResponse|error {

        return removeProperty(value);
    }


    // ------------------------------------------------------------------------
    // Search Property
    // ------------------------------------------------------------------------

    remote function SearchProperty(
        SearchPropertyRequest value
    ) returns SearchPropertyResponse|error {

        return searchProperty(value);
    }


    // ========================================================================
    // BOOKING OPERATIONS - SIMPLE RPCs
    // ========================================================================


    // ------------------------------------------------------------------------
    // Add Property to Cart
    // ------------------------------------------------------------------------

    remote function BookProperty(
        BookPropertyRequest value
    ) returns BookPropertyResponse|error {

        return bookProperty(value);
    }


    // ------------------------------------------------------------------------
    // Confirm Booking
    // ------------------------------------------------------------------------

    remote function ConfirmBooking(
        ConfirmBookingRequest value
    ) returns ConfirmBookingResponse|error {

        return confirmBooking(value);
    }


    // ========================================================================
    // USER LOOKUP - SIMPLE RPC
    // ========================================================================


    // ------------------------------------------------------------------------
    // Search User
    // ------------------------------------------------------------------------

    remote function SearchUser(
        SearchUserRequest value
    ) returns SearchUserResponse|error {

        return searchUser(value);
    }


    // ========================================================================
    // BOOKING LOOKUP / REMOVAL - SIMPLE RPCs
    // ========================================================================


    // ------------------------------------------------------------------------
    // Search Booking
    //
    // The handler checks:
    //
    // 1. Active bookings
    // 2. Removed booking history
    // ------------------------------------------------------------------------

    remote function SearchBooking(
        SearchBookingRequest value
    ) returns SearchBookingResponse|error {

        return searchBooking(value);
    }


    // ------------------------------------------------------------------------
    // Remove Booking
    //
    // The booking is archived into removed_bookings before being deleted from
    // the active bookings table.
    // ------------------------------------------------------------------------

    remote function RemoveBooking(
        RemoveBookingRequest value
    ) returns RemoveBookingResponse|error {

        return removeBooking(value);
    }


    // ========================================================================
    // CLIENT-SIDE STREAMING
    // ========================================================================


    // ------------------------------------------------------------------------
    // Create Users
    //
    // Client:
    //
    //      User
    //      User
    //      User
    //        ↓
    //
    // Server:
    //
    //      One CreateUsersResponse
    //
    // registerUser() adds each user to usersTable.
    // ------------------------------------------------------------------------

    remote function CreateUsers(
        stream<User, grpc:Error?> clientStream
    ) returns CreateUsersResponse|error {

        int created = 0;

        string[] failures = [];

        User[] createdUsers = [];


        // --------------------------------------------------------------------
        // Consume the incoming client stream.
        //
        // registerUser() now returns:
        //
        // UserRecord
        //      Successful insert.
        //
        // ServiceError
        //      Business/validation failure.
        //
        // error
        //      Unexpected service error.
        //
        // `check` propagates unexpected service errors.
        // --------------------------------------------------------------------

        error? streamError =
            from User incomingUser in clientStream
            do {

                UserRecord|ServiceError result =
                    check registerUser(
                        incomingUser
                    );


                if result is UserRecord {

                    created += 1;


                    // --------------------------------------------------------
                    // Return the server-generated user ID to the client.
                    // --------------------------------------------------------

                    createdUsers.push(
                        toProtoUser(
                            result
                        )
                    );

                } else {

                    // --------------------------------------------------------
                    // Validation/business failure.
                    // --------------------------------------------------------

                    failures.push(
                        result.message
                    );
                }
            };


        // --------------------------------------------------------------------
        // This can represent:
        //
        // - a client stream failure
        // - an error propagated by registerUser()
        // --------------------------------------------------------------------

        if streamError is error {

            return streamError;
        }


        // --------------------------------------------------------------------
        // Build response summary.
        // --------------------------------------------------------------------

        string summary =
            failures.length() == 0
            ? string `Registered ${created} user(s).`
            : string
                `Registered ${created} user(s). ${failures.length()} failed: ${failures.toString()}`;


        return {
            created_count: created,
            message: summary,
            created_users: createdUsers
        };
    }


    // ========================================================================
    // SERVER-SIDE STREAMING
    // ========================================================================


    // ------------------------------------------------------------------------
    // List Available Properties
    //
    // collectAvailable() ALREADY returns Property[].
    //
    // This is why you must NOT declare:
    //
    //     PropertyRecord[] matches
    //
    // anymore.
    // ------------------------------------------------------------------------

    remote function ListAvailableProperties(
        RentalServicePropertyCaller caller,
        ListAvailableRequest value
    ) returns error? {

        Property[] properties =
            check collectAvailable(value);

        foreach Property property in properties {

            check caller->sendProperty(
                property
            );
        }

        // Explicitly terminate the server stream.
        check caller->complete();

        return;
    }


    // ------------------------------------------------------------------------
    // List Users
    //
    // USER_ROLE_UNSPECIFIED -> everybody
    // HOST                  -> hosts only
    // GUEST                 -> guests only
    // ------------------------------------------------------------------------

    remote function ListUsers(
        RentalServiceUserCaller caller,
        ListUsersRequest value
    ) returns error? {

        User[] users =
            check collectUsers(value);

        foreach User user in users {

            check caller->sendUser(
                user
            );
        }

        check caller->complete();

        return;
    }


    // ------------------------------------------------------------------------
    // List Active Bookings
    //
    // Optional filters:
    //
    // guest_id
    // property_id
    // ------------------------------------------------------------------------

    remote function ListBookings(
            RentalServiceBookingCaller caller,
            ListBookingsRequest value
        ) returns error? {

            Booking[] bookings =
                check collectBookings(value);

            foreach Booking booking in bookings {

                check caller->sendBooking(
                    booking
                );
            }

            check caller->complete();

            return;
    }


    // ------------------------------------------------------------------------
    // List Removed Booking History
    //
    // These records come from removedBookingsTable.
    // ------------------------------------------------------------------------

    remote function ListRemovedBookings(
        RentalServiceRemovedBookingCaller caller,
        ListRemovedBookingsRequest value
    ) returns error? {

        RemovedBooking[] removedBookings =
            check collectRemovedBookings(
                value
            );

        foreach RemovedBooking removedBooking
            in removedBookings {

            check caller->sendRemovedBooking(
                removedBooking
            );
        }

        check caller->complete();

        return;
    }
}
