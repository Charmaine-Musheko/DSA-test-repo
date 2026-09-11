from django.urls import path
from . import views

urlpatterns = [
    path("assets/", views.asset_list),
    path("assets/overdue/", views.overdue_dashboard),
    path("assets/<str:asset_tag>/", views.asset_detail),
    path("assets/<str:asset_tag>/loan/", views.loan_asset),
    path("assets/<str:asset_tag>/schedules/", views.add_schedule),
    path("assets/institution/<str:institution>/", views.assets_by_institution),
    path("assets/institution/<str:institution>/site/<str:site>/", views.assets_by_institution_site),
    path("institutions/", views.institution_list),
]


