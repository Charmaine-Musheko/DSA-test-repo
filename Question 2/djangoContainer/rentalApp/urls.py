from django.urls import path

from . import views


app_name = "rentalApp"


urlpatterns = [

    path(
        "",
        views.dashboard,
        name="dashboard"
    ),

    path(
        "properties/",
        views.property_list,
        name="property_list"
    ),

    path(
        "properties/add/",
        views.property_create,
        name="property_create"
    ),

    path(
        "properties/search/",
        views.property_search,
        name="property_search"
    ),

    path(
        "book/",
        views.property_book,
        name="property_book"
    ),

    path(
        "booking/confirm/",
        views.booking_confirm,
        name="booking_confirm"
    ),
]


