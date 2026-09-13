import grpc

from .grpc_generated import rental_pb2
from .grpc_generated import rental_pb2_grpc


GRPC_SERVER = "localhost:9090"


def get_rental_stub():
    """
    Creates a gRPC channel to the Ballerina RentalService.

    Django does NOT access PostgreSQL directly.

    Django
        -> gRPC
        -> Ballerina RentalService
        -> PostgreSQL
    """

    channel = grpc.insecure_channel(GRPC_SERVER)

    return rental_pb2_grpc.RentalServiceStub(channel)


def add_property(
    host_id,
    name,
    location,
    region,
    property_type,
    price_per_night,
    description,
):
    stub = get_rental_stub()

    request = rental_pb2.AddPropertyRequest(
        host_id=host_id,
        name=name,
        location=location,
        region=region,
        property_type=property_type,
        price_per_night=float(price_per_night),
        description=description,
    )

    return stub.AddProperty(request)


def search_property(property_id):
    stub = get_rental_stub()

    request = rental_pb2.SearchPropertyRequest(
        property_id=property_id
    )

    return stub.SearchProperty(request)


def list_available_properties(
    location_filter="",
    min_price=0.0,
    max_price=0.0,
):
    stub = get_rental_stub()

    request = rental_pb2.ListAvailableRequest(
        location_filter=location_filter,
        min_price=float(min_price),
        max_price=float(max_price),
    )

    # This returns an iterator because the Ballerina service
    # performs server-side streaming.
    return stub.ListAvailableProperties(request)


def update_property(
    property_id,
    price_per_night=None,
    description=None,
    status=None,
):
    stub = get_rental_stub()

    request = rental_pb2.UpdatePropertyRequest(
        property_id=property_id
    )

    if price_per_night is not None:
        request.price_per_night = float(price_per_night)

    if description is not None:
        request.description = description

    if status is not None:
        request.status = status

    return stub.UpdateProperty(request)


def book_property(
    guest_id,
    property_id,
    check_in,
    check_out,
):
    stub = get_rental_stub()

    request = rental_pb2.BookPropertyRequest(
        guest_id=guest_id,
        property_id=property_id,
        dates=rental_pb2.DateRange(
            check_in=check_in,
            check_out=check_out,
        ),
    )

    return stub.BookProperty(request)


def confirm_booking(guest_id, cart_id):
    stub = get_rental_stub()

    request = rental_pb2.ConfirmBookingRequest(
        guest_id=guest_id,
        cart_id=cart_id,
    )

    return stub.ConfirmBooking(request)


def remove_property(property_id):
    stub = get_rental_stub()

    request = rental_pb2.RemovePropertyRequest(
        property_id=property_id
    )

    return stub.RemoveProperty(request)


