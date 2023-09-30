from rest_framework.viewsets import ModelViewSet
from rest_framework.exceptions import ValidationError
from django.shortcuts import get_object_or_404


from api.serializers import (
    CountrySerializer,
    CommoditySerializer,
    ProductionSerializer,
    ReservesSerializer,
    GovInfoSerializer,
    ImportDataSerializer,
    ExportDataSerializer,
    CommodityPriceSerializer,
    ImportExportBalanceSerializer,
)

from api.models import (
    Country,
    HarvardCountry,
    Commodity,
    HarvardCommodity,
    Production,
    Reserves,
    GovInfo,
    ImportData,
    ExportData,
    CommodityPrice,
    ImportExportBalance,
)


class BaseFilterViewSet(ModelViewSet):
    filter_param_mapping = {}

    def get_queryset(self):
        queryset = super().get_queryset()
        for param, field in self.filter_param_mapping.items():
            value = self.request.query_params.get(param)
            if value:
                queryset = queryset.filter(**{field: value})
        return queryset


class BaseImportExportViewSet(ModelViewSet):
    def get_queryset(self):
        queryset = super().get_queryset()

        params = {
            "year": self.request.query_params.get("year"),
            "country": self.request.query_params.get("country"),
            "commodity": self.request.query_params.get("commodity"),
        }

        param_count = sum(1 for param in params.values() if param)

        if param_count < 2:
            raise ValidationError("At least two parameters must be passed")

        if params["year"]:
            queryset = queryset.filter(year=params["year"])

        if params["country"]:
            country = get_object_or_404(Country, name=params["country"])
            harvard_countries = HarvardCountry.objects.filter(country_id=country)
            queryset = queryset.filter(country__in=harvard_countries)

        if params["commodity"]:
            commodity = get_object_or_404(Commodity, name=params["commodity"])
            harvard_commodities = HarvardCommodity.objects.filter(
                commodity_id=commodity
            )
            queryset = queryset.filter(commodity__in=harvard_commodities)

        return queryset


class ImportDataViewSet(BaseImportExportViewSet):
    queryset = ImportData.objects.all()
    serializer_class = ImportDataSerializer


class ExportDataViewSet(BaseImportExportViewSet):
    queryset = ExportData.objects.all()
    serializer_class = ExportDataSerializer


class CountryViewSet(BaseFilterViewSet):
    queryset = Country.objects.all()
    serializer_class = CountrySerializer
    filter_param_mapping = {"name": "name"}


class CommodityViewSet(BaseFilterViewSet):
    queryset = Commodity.objects.all()
    serializer_class = CommoditySerializer
    filter_param_mapping = {"name": "name"}


class ProductionViewSet(BaseFilterViewSet):
    queryset = Production.objects.all()
    serializer_class = ProductionSerializer
    filter_param_mapping = {
        "year": "year",
        "commodity": "commodity__name",
        "country": "country__name",
    }


class ReservesViewSet(BaseFilterViewSet):
    queryset = Reserves.objects.all()
    serializer_class = ReservesSerializer
    filter_param_mapping = {
        "year": "year",
        "commodity": "commodity__name",
        "country": "country__name",
    }


class GovInfoViewSet(BaseFilterViewSet):
    queryset = GovInfo.objects.all()
    serializer_class = GovInfoSerializer
    filter_param_mapping = {"year": "year", "commodity": "commodity__name"}


class CommodityPriceViewSet(BaseFilterViewSet):
    queryset = CommodityPrice.objects.all()
    serializer_class = CommodityPriceSerializer
    filter_param_mapping = {"commodity": "commodity__name"}


class ImportExportBalanceViewset(BaseFilterViewSet):
    queryset = ImportExportBalance.objects.all()
    serializer_class = ImportExportBalanceSerializer
    filter_param_mapping = {"country": "country__name", "year": "year"}
