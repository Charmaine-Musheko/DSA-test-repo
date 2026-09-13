from django.urls import path

from . import views


app_name = "rentalApp"


urlpatterns = [

    # Dashboard
    path("", views.dashboard, name="dashboard"),


    # ========================================================================
    # USERS
    # ========================================================================

    path("users/", views.user_list, name="user_list"),

    path("users/create/", views.user_create, name="user_create"),

    path("users/search/", views.user_search, name="user_search"),


    # ========================================================================
    # PROPERTIES
    # ========================================================================

    path("properties/", views.property_list, name="property_list"),

    path("properties/add/", views.property_create, name="property_create"),

    path("properties/search/", views.property_search, name="property_search"),

    path("properties/update/", views.property_update, name="property_update"),

    path("properties/remove/", views.property_remove, name="property_remove"),


    # ========================================================================
    # CART / BOOKING
    # ========================================================================

    path("book/", views.property_book, name="property_book"),

    path("booking/confirm/", views.booking_confirm, name="booking_confirm"),

    path("bookings/", views.booking_list, name="booking_list"),

    path("bookings/search/", views.booking_search, name="booking_search"),

    path("bookings/remove/", views.booking_remove, name="booking_remove"),

    path("bookings/removed/", views.removed_booking_list, name="removed_booking_list"),
]