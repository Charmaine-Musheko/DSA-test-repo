import grpc

from .grpc_generated import rental_pb2
from .grpc_generated import rental_pb2_grpc


GRPC_SERVER = "localhost:9090"


def get_stub():
    """
    Django communicates ONLY with the Ballerina gRPC service.

    Django
        -> gRPC
        -> Ballerina
        -> PostgreSQL
    """

    channel = grpc.insecure_channel(GRPC_SERVER)
    return rental_pb2_grpc.RentalServiceStub(channel)


# ============================================================================
# USERS
# ============================================================================

def create_users(users):
    """
    Client-side streaming.

    users is a list such as:

    [
        {
            "name": "Katrina",
            "email": "kat@example.com",
            "role": "HOST",
            "region": "Erongo"
        }
    ]
    """

    stub = get_stub()

    def request_iterator():

        for user in users:

            role = (
                rental_pb2.HOST
                if user["role"] == "HOST"
                else rental_pb2.GUEST
            )

            yield rental_pb2.User(
                user_id="",
                name=user["name"],
                email=user["email"],
                role=role,
                region=user.get("region", ""),
            )

    return stub.CreateUsers(
        request_iterator()
    )


def list_users(role=""):
    stub = get_stub()

    role_filter = rental_pb2.USER_ROLE_UNSPECIFIED

    if role == "HOST":
        role_filter = rental_pb2.HOST

    elif role == "GUEST":
        role_filter = rental_pb2.GUEST

    return stub.ListUsers(
        rental_pb2.ListUsersRequest(
            role_filter=role_filter
        )
    )


def search_user(user_id):
    stub = get_stub()

    return stub.SearchUser(
        rental_pb2.SearchUserRequest(
            user_id=user_id
        )
    )


# ============================================================================
# PROPERTIES
# ============================================================================

def add_property(
    host_id,
    name,
    location,
    region,
    property_type,
    price_per_night,
    description,
):
    stub = get_stub()

    return stub.AddProperty(
        rental_pb2.AddPropertyRequest(
            host_id=host_id,
            name=name,
            location=location,
            region=region,
            property_type=property_type,
            price_per_night=float(price_per_night),
            description=description,
        )
    )


def list_available_properties(
    location_filter="",
    min_price=0.0,
    max_price=0.0,
):
    stub = get_stub()

    return stub.ListAvailableProperties(
        rental_pb2.ListAvailableRequest(
            location_filter=location_filter,
            min_price=float(min_price),
            max_price=float(max_price),
    ),
    timeout=5,
)

    

def search_property(property_id):
    stub = get_stub()

    return stub.SearchProperty(
        rental_pb2.SearchPropertyRequest(
            property_id=property_id
        )
    )


def update_property(
    property_id,
    price_per_night=None,
    status=None,
    description=None,
):
    stub = get_stub()

    request = rental_pb2.UpdatePropertyRequest(
        property_id=property_id
    )

    if price_per_night not in (None, ""):
        request.price_per_night = float(price_per_night)

    if description not in (None, ""):
        request.description = description

    if status == "AVAILABLE":
        request.status = rental_pb2.AVAILABLE

    elif status == "BOOKED":
        request.status = rental_pb2.BOOKED

    elif status == "UNDER_MAINTENANCE":
        request.status = rental_pb2.UNDER_MAINTENANCE

    elif status == "DELISTED":
        request.status = rental_pb2.DELISTED

    return stub.UpdateProperty(request)


def remove_property(property_id):
    stub = get_stub()

    return stub.RemoveProperty(
        rental_pb2.RemovePropertyRequest(
            property_id=property_id
        )
    )


# ============================================================================
# BOOKING / CART
# ============================================================================

def book_property(
    guest_id,
    property_id,
    check_in,
    check_out,
):
    stub = get_stub()

    return stub.BookProperty(
        rental_pb2.BookPropertyRequest(
            guest_id=guest_id,
            property_id=property_id,
            dates=rental_pb2.DateRange(
                check_in=check_in,
                check_out=check_out,
            ),
        )
    )


def confirm_booking(
    guest_id,
    cart_id,
):
    stub = get_stub()

    return stub.ConfirmBooking(
        rental_pb2.ConfirmBookingRequest(
            guest_id=guest_id,
            cart_id=cart_id,
        )
    )


def list_bookings(
    guest_id="",
    property_id="",
):
    stub = get_stub()

    return stub.ListBookings(
        rental_pb2.ListBookingsRequest(
            guest_id=guest_id,
            property_id=property_id,
        )
    )


def search_booking(booking_id):
    stub = get_stub()

    return stub.SearchBooking(
        rental_pb2.SearchBookingRequest(
            booking_id=booking_id
        )
    )


def remove_booking(
    booking_id,
    reason,
):
    stub = get_stub()

    return stub.RemoveBooking(
        rental_pb2.RemoveBookingRequest(
            booking_id=booking_id,
            reason=reason,
        )
    )


def list_removed_bookings(
    guest_id="",
    property_id="",
):
    stub = get_stub()

    return stub.ListRemovedBookings(
        rental_pb2.ListRemovedBookingsRequest(
            guest_id=guest_id,
            property_id=property_id,
        )
    )