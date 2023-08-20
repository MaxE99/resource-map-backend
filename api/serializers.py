from rest_framework.serializers import ModelSerializer

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


class ReadOnlyModelSerializer(ModelSerializer):
    def get_fields(self, *args, **kwargs):
        fields = super().get_fields(*args, **kwargs)
        for field in fields:
            fields[field].read_only = True
        return fields


class CountrySerializer(ReadOnlyModelSerializer):
    class Meta:
        model = Country


class CommoditySerializer(ReadOnlyModelSerializer):
    class Meta:
        model = Commodity


class ProductionSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = Production


class ReservesSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = Reserves


class GovInfoSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = GovInfo


class ImportDataSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = ImportData


class ExportDataSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = ExportData


class CommodityPriceSerializer(ReadOnlyModelSerializer):
    class Meta:
        model = CommodityPrice
