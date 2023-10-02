from django.urls import path, include
from rest_framework import routers

from api.api import (
    CountryViewSet,
    CommodityViewSet,
    ProductionViewSet,
    ReservesViewSet,
    GovInfoViewSet,
    ImportDataViewSet,
    ExportDataViewSet,
    CommodityPriceViewSet,
    ImportExportBalanceViewset,
    ResourceStronghold,
)


app_name = "api"

router = routers.DefaultRouter()
router.register("countries", CountryViewSet)
router.register("commodities", CommodityViewSet)
router.register("production", ProductionViewSet)
router.register("reserves", ReservesViewSet)
router.register("gov_info", GovInfoViewSet)
router.register("imports", ImportDataViewSet)
router.register("exports", ExportDataViewSet)
router.register("prices", CommodityPriceViewSet)
router.register("balance", ImportExportBalanceViewset)
router.register("stronghold", ResourceStronghold)

urlpatterns = [
    path("", include(router.urls)),
]
