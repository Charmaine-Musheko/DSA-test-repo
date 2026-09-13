import ballerina/io;
import ballerina/grpc;

public function main() returns error? {

    // -----------------------------------------------------------------------
    // Connect to the gRPC server.
    //
    // IMPORTANT:
    // Do not use "client" as the variable name because "client" is a
    // Ballerina language qualifier/keyword.
    // -----------------------------------------------------------------------
    RentalServiceClient rentalClient = check new ("http://localhost:9090");

    // -----------------------------------------------------------------------
    // 1. Register a host and a guest via client-side streaming.
    //
    // CreateUsers() returns a streaming client. We send users one at a time,
    // complete the stream, and then receive the single server response.
    // -----------------------------------------------------------------------
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

    // Tell the server that the client has finished sending users.
    check userStream->complete();

    // Receive the final response from the server.
    CreateUsersResponse? userResp =
        check userStream->receiveCreateUsersResponse();

    io:println("[create_users] ", userResp);


    // -----------------------------------------------------------------------
    // 2. Host adds two properties.
    // -----------------------------------------------------------------------

    AddPropertyResponse p1 = check rentalClient->AddProperty({
        host_id: "HOST-001",
        name: "Dune View Apartment",
        location: "Swakopmund, Erongo",
        region: "Erongo",
        property_type: "Apartment",
        price_per_night: 850.0,
        description: "Two-bedroom with ocean view."
    });

    io:println("[add_property #1] ", p1);


    AddPropertyResponse p2 = check rentalClient->AddProperty({
        host_id: "HOST-001",
        name: "Kalahari Lodge",
        location: "Windhoek, Khomas",
        region: "Khomas",
        property_type: "Lodge",
        price_per_night: 1200.0,
        description: "Desert lodge with pool."
    });

    io:println("[add_property #2] ", p2);


    // -----------------------------------------------------------------------
    // 3. Server-side streaming:
    //    List all available properties without any filters.
    // -----------------------------------------------------------------------

    io:println("[list_available] all:");

    stream<Property, grpc:Error?> all =
        check rentalClient->ListAvailableProperties({});

    check drain(all);


    // -----------------------------------------------------------------------
    // 4. Server-side streaming with filters.
    //
    // We only want:
    //   - Properties matching "Erongo"
    //   - Minimum price: N$0
    //   - Maximum price: N$1000/night
    // -----------------------------------------------------------------------

    io:println("[list_available] Erongo <= 1000/night:");

    stream<Property, grpc:Error?> filtered =
        check rentalClient->ListAvailableProperties({
            location_filter: "Erongo",
            min_price: 0.0,
            max_price: 1000.0
        });

    check drain(filtered);


    // -----------------------------------------------------------------------
    // 5. Search for the first property by its generated property ID.
    // -----------------------------------------------------------------------

    SearchPropertyResponse search =
        check rentalClient->SearchProperty({
            property_id: p1.property_id
        });

    io:println("[search_property] ", search);


    // -----------------------------------------------------------------------
    // 6. Update the price of the first property.
    // -----------------------------------------------------------------------

    UpdatePropertyResponse upd =
        check rentalClient->UpdateProperty({
            property_id: p1.property_id,
            price_per_night: 900.0
        });

    io:println("[update_property] ", upd);


    // -----------------------------------------------------------------------
    // 7. Book the first property.
    //
    // At this point the booking is added to the guest's cart. It is not yet
    // considered a confirmed reservation.
    // -----------------------------------------------------------------------

    BookPropertyResponse cart =
        check rentalClient->BookProperty({
            guest_id: "GUEST-001",
            property_id: p1.property_id,
            dates: {
                check_in: "2026-10-01",
                check_out: "2026-10-05"
            }
        });

    io:println("[book_property] ", cart);


    // -----------------------------------------------------------------------
    // 8. Confirm the booking.
    //
    // The server should validate availability before converting the cart
    // entry into a confirmed reservation.
    // -----------------------------------------------------------------------

    ConfirmBookingResponse confirm =
        check rentalClient->ConfirmBooking({
            guest_id: "GUEST-001",
            cart_id: cart.cart_id
        });

    io:println("[confirm_booking] ", confirm);


    // -----------------------------------------------------------------------
    // 9. Attempt an overlapping booking.
    //
    // Existing confirmed booking:
    //     2026-10-01 -> 2026-10-05
    //
    // New attempt:
    //     2026-10-03 -> 2026-10-07
    //
    // These ranges overlap, so ConfirmBooking should reject the request.
    // -----------------------------------------------------------------------

    BookPropertyResponse cart2 =
        check rentalClient->BookProperty({
            guest_id: "GUEST-001",
            property_id: p1.property_id,
            dates: {
                check_in: "2026-10-03",
                check_out: "2026-10-07"
            }
        });

    ConfirmBookingResponse confirm2 =
        check rentalClient->ConfirmBooking({
            guest_id: "GUEST-001",
            cart_id: cart2.cart_id
        });

    io:println(
        "[confirm_booking overlap — expect failure] ",
        confirm2
    );


    // -----------------------------------------------------------------------
    // 10. Remove the second property.
    // -----------------------------------------------------------------------

    RemovePropertyResponse removed =
        check rentalClient->RemoveProperty({
            property_id: p2.property_id
        });

    io:println("[remove_property] ", removed);


    return;
}


// ---------------------------------------------------------------------------
// Helper function for server-side streaming.
//
// The gRPC server sends Property objects one by one. The stream is consumed
// using a Ballerina query expression.
//
// If the stream encounters a gRPC error, the error is returned to main().
// ---------------------------------------------------------------------------
function drain(stream<Property, grpc:Error?> propertyStream) returns error? {

    error? streamError =
        from Property property in propertyStream
        do {
            io:println("   -> ", property);
        };

    return streamError;
}