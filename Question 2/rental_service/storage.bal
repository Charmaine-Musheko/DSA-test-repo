import ballerina/time;

table<PropertyRecord> key(propertyId) propertiesTable = table [];
table<UserRecord> key(userId) usersTable = table [];
table<BookingRecord> key(bookingId) bookingsTable = table [];
table<CartItem> key(cartId) cartTable = table [];

int propertyCounter = 0;
int userCounter = 0;
int bookingCounter = 0;
int cartCounter = 0;

function nextPropertyId() returns string {
    propertyCounter += 1;
    return string `PROP-${propertyCounter.toString().padStart(4, "0")}`;
}

function nextUserId() returns string {
    userCounter += 1;
    return string `USR-${userCounter.toString().padStart(4, "0")}`;
}

function nextBookingId() returns string {
    bookingCounter += 1;
    return string `BKG-${bookingCounter.toString().padStart(4, "0")}`;
}

function nextCartId() returns string {
    cartCounter += 1;
    return string `CART-${cartCounter.toString().padStart(4, "0")}`;
}

function todayIso() returns string {
    time:Utc now = time:utcNow();
    time:Civil civil = time:utcToCivil(now);
    string mm = civil.month < 10 ? string `0${civil.month}` : civil.month.toString();
    string dd = civil.day < 10 ? string `0${civil.day}` : civil.day.toString();
    return string `${civil.year}-${mm}-${dd}`;
}