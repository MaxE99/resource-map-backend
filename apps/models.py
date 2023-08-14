"""
This module defines Django models for representing data related to countries, commodities, production, reserves,
imports, exports, commodity prices, and government information about commodities.

It includes abstract base models for production, reserves, imports, and exports, as well as concrete models for
specific data categories.
"""

from django.db.models import (
    AutoField,
    BigIntegerField,
    CASCADE,
    CharField,
    DateField,
    DecimalField,
    ForeignKey,
    Index,
    IntegerField,
    Model,
    TextField,
)
from django.core.exceptions import ValidationError


def non_negative_validator(value):
    """
    Validator function to ensure that the given value is non-negative.

    Args:
        value (float or int): The value to be validated.

    Raises:
        ValidationError: If the value is negative.
    """
    if value < 0:
        raise ValidationError("This value must be non-negative.")


class Country(Model):
    """
    A model representing a country.
    """

    id = AutoField(primary_key=True)
    name = CharField(unique=True, max_length=100)
    flag_path = CharField(
        max_length=500, blank=True
    )  # the link to the flag of the country
    ease_of_biz = DecimalField(
        blank=True,
        null=True,
        max_digits=3,
        decimal_places=1,
        validators=[non_negative_validator],
    )  # ease of doing business index
    gdp = BigIntegerField(blank=True, null=True, validators=[non_negative_validator])

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Commodity(Model):
    """
    Model representing a commodity.
    """

    id = AutoField(primary_key=True)
    name = CharField(unique=True, max_length=100)

    def __str__(self) -> str:
        return self.name


class ProductionReservesBase(Model):
    """
    Abstract base model for production and reserves data.
    """

    METRIC_CHOICES = [
        ("kg", "Kilograms"),
        ("MT", "Metric Ton"),
    ]

    id = AutoField(primary_key=True)
    year = IntegerField()
    country = ForeignKey(Country, on_delete=CASCADE)
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    note = CharField(
        blank=True, null=True, max_length=100
    )  # extra note about type of production/reserves
    metric = CharField(max_length=50, choices=METRIC_CHOICES)
    amount = DecimalField(
        max_digits=10, decimal_places=2, validators=[non_negative_validator]
    )

    class Meta:
        abstract = True
        indexes = [
            Index(fields=["year", "country", "commodity"]),
        ]


class ImportExportBase(Model):
    """
    Abstract base model for import and export data.
    """

    id = AutoField(primary_key=True)
    year = IntegerField()
    country = ForeignKey(Country, on_delete=CASCADE)
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    amount = DecimalField(
        validators=[non_negative_validator],
        max_digits=15,
        decimal_places=10,
    )
    share = DecimalField(
        validators=[non_negative_validator], max_digits=3, decimal_places=10
    )

    class Meta:
        indexes = [
            Index(fields=["year", "country", "commodity"]),
        ]


class Reserves(ProductionReservesBase):
    """
    Model representing reserves data.
    """

    def __str__(self) -> str:
        return f"Reserves: {self.year} - {self.country} - {self.commodity}"


class Production(ProductionReservesBase):
    """
    Model representing production data.
    """

    def __str__(self) -> str:
        return f"Reserves: {self.year} - {self.country} - {self.commodity}"


class GovInfo(Model):
    """
    Model representing United States government information about commodities.
    """

    id = AutoField(primary_key=True)
    year = IntegerField()
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    prod_and_use = TextField()  # domnestic production and use
    recycling = TextField()
    events = TextField()  # events, trends and issues
    world_resources = TextField()
    substitutes = TextField()

    class Meta:
        indexes = [
            Index(fields=["year", "commodity"]),
        ]

    def __str__(self) -> str:
        return f"{self.year}: {self.commodity}"


class ImportData(ImportExportBase):
    """
    Model representing import data.
    """

    def __str__(self) -> str:
        return f"Import: {self.year} - {self.country} - {self.commodity}"


class ExportData(ImportExportBase):
    """
    Model representing export data.
    """

    def __str__(self) -> str:
        return f"Export: {self.year} - {self.country} - {self.commodity}"


class CommodityPrice(Model):
    """
    Model representing commodity prices.
    """

    id = AutoField(primary_key=True)
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    date = DateField()
    price = DecimalField(
        validators=[non_negative_validator],
        max_digits=9,
        decimal_places=4,
    )

    class Meta:
        indexes = [
            Index(fields=["commodity"]),
        ]

    def __str__(self) -> str:
        return f"{self.commodity}: {self.date}"


# need more information for the following models
#   1.Climate
#   2.Companies
#   3.Investment into new production
#   4.General/Other Informations
#   5.Substitutes
