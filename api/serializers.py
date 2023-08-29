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


def create_read_only_serializer(model_class):
    class Meta:
        model = model_class
        fields = "__all__"

    return type(
        f"{model_class.__name__}Serializer", (ReadOnlyModelSerializer,), {"Meta": Meta}
    )


CountrySerializer = create_read_only_serializer(Country)
CommoditySerializer = create_read_only_serializer(Commodity)
ProductionSerializer = create_read_only_serializer(Production)
ReservesSerializer = create_read_only_serializer(Reserves)
GovInfoSerializer = create_read_only_serializer(GovInfo)
ImportDataSerializer = create_read_only_serializer(ImportData)
ExportDataSerializer = create_read_only_serializer(ExportData)
CommodityPriceSerializer = create_read_only_serializer(CommodityPrice)
