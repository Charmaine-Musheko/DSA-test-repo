// The rental service deliberately uses only Ballerina in-memory collections.
// Each table has a stable business ID as its key, giving fast keyed lookups
// and preventing duplicate IDs without an external database.

table<UserRecord> key(userId) usersTable = table [];
table<PropertyRecord> key(propertyId) propertiesTable = table [];
table<CartItem> key(cartId) cartItemsTable = table [];
table<BookingRecord> key(bookingId) bookingsTable = table [];
table<RemovedBookingRecord> key(bookingId) removedBookingsTable = table [];

int userSequence = 0;
int propertySequence = 0;
int cartSequence = 0;
int bookingSequence = 0;

function formattedId(string prefix, int number) returns string {
    return string `${prefix}-${number.toString().padStart(4, "0")}`;
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

function getUser(string userId) returns UserRecord?|error {
    return usersTable[userId];
}

function insertUser(
    string name,
    string email,
    string role,
    string region
) returns UserRecord|error {
    string normalizedEmail = email.trim().toLowerAscii();
    foreach UserRecord existing in usersTable {
        if existing.email.trim().toLowerAscii() == normalizedEmail {
            return error(string `A user with email '${email}' already exists`);
        }
    }

    userSequence += 1;
    UserRecord user = {
        userId: formattedId("USR", userSequence),
        name: name,
        email: email,
        role: role,
        region: region
    };
    usersTable.add(user);
    return user;
}

function listUserRecords(string role) returns UserRecord[]|error {
    return from UserRecord user in usersTable
        where role == "" || user.role == role
        select user;
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

function getProperty(string propertyId) returns PropertyRecord?|error {
    return propertiesTable[propertyId];
}

function insertProperty(
    string hostId,
    string name,
    string location,
    string region,
    string propertyType,
    decimal pricePerNight,
    string description
) returns PropertyRecord|error {
    propertySequence += 1;
    PropertyRecord property = {
        propertyId: formattedId("PROP", propertySequence),
        hostId: hostId,
        name: name,
        location: location,
        region: region,
        propertyType: propertyType,
        pricePerNight: pricePerNight,
        status: "AVAILABLE",
        description: description
    };
    propertiesTable.add(property);
    return property;
}

function updatePropertyRecord(PropertyRecord property) returns error? {
    propertiesTable.put(property);
}

function deletePropertyRecord(string propertyId) returns error? {
    _ = propertiesTable.remove(propertyId);
}

function listAvailablePropertyRecords(
    string locationFilter,
    float minPrice,
    float maxPrice
) returns PropertyRecord[]|error {
    string normalizedLocation = locationFilter.trim().toLowerAscii();
    return from PropertyRecord property in propertiesTable
        where property.status == "AVAILABLE"
            && (normalizedLocation == "" ||
                property.location.toLowerAscii().includes(normalizedLocation))
            && (minPrice <= 0.0 || property.pricePerNight >= <decimal>minPrice)
            && (maxPrice <= 0.0 || property.pricePerNight <= <decimal>maxPrice)
        select property;
}

function listAvailablePropertiesInRegion(
    string region
) returns PropertyRecord[]|error {
    return from PropertyRecord property in propertiesTable
        where property.region == region && property.status == "AVAILABLE"
        select property;
}

// ---------------------------------------------------------------------------
// Cart items
// ---------------------------------------------------------------------------

function insertCartItem(
    string guestId,
    string propertyId,
    string checkIn,
    string checkOut
) returns CartItem|error {
    cartSequence += 1;
    CartItem cart = {
        cartId: formattedId("CART", cartSequence),
        guestId: guestId,
        propertyId: propertyId,
        checkIn: checkIn,
        checkOut: checkOut
    };
    cartItemsTable.add(cart);
    return cart;
}

function getCartItem(string cartId) returns CartItem?|error {
    return cartItemsTable[cartId];
}

function deleteCartItem(string cartId) returns error? {
    _ = cartItemsTable.remove(cartId);
}

// ---------------------------------------------------------------------------
// Active bookings
// ---------------------------------------------------------------------------

function hasOverlappingBooking(
    string propertyId,
    string checkIn,
    string checkOut
) returns boolean|error {
    foreach BookingRecord booking in bookingsTable {
        if booking.propertyId == propertyId &&
            booking.status == "CONFIRMED" &&
            booking.checkIn < checkOut &&
            booking.checkOut > checkIn {
            return true;
        }
    }
    return false;
}

function insertBooking(
    string propertyId,
    string guestId,
    string checkIn,
    string checkOut,
    decimal totalCost,
    string status
) returns BookingRecord|error {
    bookingSequence += 1;
    BookingRecord booking = {
        bookingId: formattedId("BKG", bookingSequence),
        propertyId: propertyId,
        guestId: guestId,
        checkIn: checkIn,
        checkOut: checkOut,
        totalCost: totalCost,
        status: status
    };
    bookingsTable.add(booking);
    return booking;
}

function getBooking(string bookingId) returns BookingRecord?|error {
    return bookingsTable[bookingId];
}

function listBookingRecords(
    string guestId,
    string propertyId
) returns BookingRecord[]|error {
    return from BookingRecord booking in bookingsTable
        where (guestId == "" || booking.guestId == guestId)
            && (propertyId == "" || booking.propertyId == propertyId)
        select booking;
}

// ---------------------------------------------------------------------------
// Removed booking history
// ---------------------------------------------------------------------------

function archiveAndDeleteBooking(
    string bookingId,
    string reason
) returns RemovedBookingRecord?|error {
    BookingRecord? existing = bookingsTable[bookingId];
    if existing is () {
        return ();
    }

    RemovedBookingRecord removed = {
        bookingId: existing.bookingId,
        propertyId: existing.propertyId,
        guestId: existing.guestId,
        checkIn: existing.checkIn,
        checkOut: existing.checkOut,
        totalCost: existing.totalCost,
        status: "CANCELLED",
        reason: reason,
        removedAt: todayIso()
    };

    removedBookingsTable.add(removed);
    _ = bookingsTable.remove(bookingId);
    return removed;
}

function getRemovedBooking(
    string bookingId
) returns RemovedBookingRecord?|error {
    return removedBookingsTable[bookingId];
}

function listRemovedBookingRecords(
    string guestId,
    string propertyId
) returns RemovedBookingRecord[]|error {
    return from RemovedBookingRecord booking in removedBookingsTable
        where (guestId == "" || booking.guestId == guestId)
            && (propertyId == "" || booking.propertyId == propertyId)
        select booking;
}
