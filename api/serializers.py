from rest_framework.serializers import ModelSerializer, CharField
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


def create_read_only_serializer(model_class):
    class Meta:
        model = model_class
        fields = "__all__"

    return type(
        f"{model_class.__name__}Serializer", (ReadOnlyModelSerializer,), {"Meta": Meta}
    )


class BaseProductionReservesSerializer(ReadOnlyModelSerializer):
    country_name = CharField(source="country.name")
    commodity_name = CharField(source="commodity.name")

    class Meta:
        fields = [
            "id",
            "year",
            "country_name",
            "note",
            "metric",
            "amount",
            "commodity_name",
            "share",
            "rank",
        ]


class ImportExportSerializer(ReadOnlyModelSerializer):
    country_name = CharField(source="country.name")
    commodity_name = CharField(source="commodity.name")

    class Meta:
        fields = [
            "id",
            "year",
            "amount",
            "share",
            "country_name",
            "commodity_name",
        ]


class ImportDataSerializer(ImportExportSerializer):
    class Meta(ImportExportSerializer.Meta):
        model = ImportData


class ExportDataSerializer(ImportExportSerializer):
    class Meta(ImportExportSerializer.Meta):
        model = ExportData


class ProductionSerializer(BaseProductionReservesSerializer):
    class Meta(BaseProductionReservesSerializer.Meta):
        model = Production


class ReservesSerializer(BaseProductionReservesSerializer):
    class Meta(BaseProductionReservesSerializer.Meta):
        model = Reserves


CountrySerializer = create_read_only_serializer(Country)
CommoditySerializer = create_read_only_serializer(Commodity)
GovInfoSerializer = create_read_only_serializer(GovInfo)
CommodityPriceSerializer = create_read_only_serializer(CommodityPrice)
