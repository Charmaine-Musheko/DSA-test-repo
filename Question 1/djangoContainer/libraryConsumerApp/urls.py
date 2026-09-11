from django.urls import path
from . import views

urlpatterns = [
    # HTML
    path("", views.dashboard, name="dashboard"),

    # Global view
    path("api/assets/", views.asset_list, name="asset-list"),
    path("api/assets/overdue/", views.overdue_dashboard, name="overdue"),

    # Campus view — must come BEFORE api/assets/<tag>/ to avoid capture
    path("api/assets/institution/<str:institution>/",
         views.assets_by_institution, name="assets-by-institution"),
    path("api/assets/institution/<str:institution>/site/<str:site>/",
         views.assets_by_institution_site, name="assets-by-site"),

    # Single-asset read is not required for the dashboard but useful
    # path("api/assets/<str:asset_tag>/", views.asset_detail, ...),

    # Loan / booking
    path("api/assets/<str:asset_tag>/loan/",
         views.loan_asset, name="loan-asset"),
    path("api/assets/<str:asset_tag>/return/",
         views.return_asset, name="return-asset"),
    path("api/assets/<str:asset_tag>/book/",
         views.book_asset, name="book-asset"),
    path("api/assets/<str:asset_tag>/release/",
         views.release_asset, name="release-asset"),

    # Schedules
    path("api/assets/<str:asset_tag>/schedules/",
         views.list_schedules, name="list-schedules"),
    path("api/assets/<str:asset_tag>/schedules/add/",
         views.add_schedule, name="add-schedule"),
    path("api/assets/<str:asset_tag>/schedules/<str:schedule_id>/delete/",
         views.delete_schedule, name="delete-schedule"),

    # Work orders
    path("api/assets/<str:asset_tag>/workorders/",
         views.list_work_orders, name="list-workorders"),
    path("api/assets/<str:asset_tag>/workorders/add/",
         views.add_work_order, name="add-workorder"),
    path("api/assets/<str:asset_tag>/workorders/<str:order_id>/update/",
         views.update_work_order, name="update-workorder"),

    # Institutions
    path("api/institutions/", views.institution_list, name="institution-list"),
    path("api/institutions/add/", views.add_institution, name="add-institution"),
    path("api/institutions/<str:name>/delete/",
         views.delete_institution, name="delete-institution"),
]


