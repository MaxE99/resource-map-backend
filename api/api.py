from rest_framework.viewsets import ModelViewSet
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
        year = self.request.query_params.get("year")
        if year:
            queryset = queryset.filter(year=year)
        country = self.request.query_params.get("country")
        if country:
            country = get_object_or_404(Country, name=country)
            tmp = HarvardCountry.objects.none()
            harvardCountries = HarvardCountry.objects.filter(country_id=country)
            for harvardCountry in harvardCountries:
                tmp = tmp | queryset.filter(country=harvardCountry)
            queryset = tmp
        commodity = self.request.query_params.get("commodity")
        if commodity:
            commodity = get_object_or_404(Commodity, name=commodity)
            tmp = HarvardCommodity.objects.none()
            harvardCommodities = HarvardCommodity.objects.filter(commodity_id=commodity)
            for harvardCommodity in harvardCommodities:
                tmp = tmp | queryset.filter(commodity=harvardCommodity)
            queryset = tmp
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
