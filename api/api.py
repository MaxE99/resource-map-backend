from rest_framework.viewsets import ModelViewSet

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
    Commodity,
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


class ImportDataViewSet(BaseFilterViewSet):
    queryset = ImportData.objects.all()
    serializer_class = ImportDataSerializer
    filter_param_mapping = {
        "year": "year",
        "commodity": "commodity__name",
        "country": "country__name",
    }


class ExportDataViewSet(BaseFilterViewSet):
    queryset = ExportData.objects.all()
    serializer_class = ExportDataSerializer
    filter_param_mapping = {
        "year": "year",
        "commodity": "commodity__name",
        "country": "country__name",
    }


class CommodityPriceViewSet(BaseFilterViewSet):
    queryset = CommodityPrice.objects.all()
    serializer_class = CommodityPriceSerializer
    filter_param_mapping = {"commodity": "commodity__name"}
