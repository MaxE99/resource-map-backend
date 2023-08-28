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
    UniqueConstraint,
)
from django.contrib.postgres.fields import ArrayField
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

    INCOME_CHOICES = [
        ("High income", "High income"),
        ("Upper middle income", "Upper middle income"),
        ("Lower middle income", "Lower middle income"),
        ("Low income", "Low income"),
    ]

    id = AutoField(primary_key=True)
    name = CharField(unique=True, max_length=100)
    flag_path = CharField(
        max_length=500, blank=True
    )  # the link to the flag of the country
    ease_of_biz = DecimalField(
        blank=True,
        null=True,
        max_digits=4,
        decimal_places=1,
        validators=[non_negative_validator],
    )  # ease of doing business index
    income_group = CharField(
        blank=True, null=True, max_length=50, choices=INCOME_CHOICES
    )
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
    info = TextField(blank=True, null=True)
    img_path = CharField(max_length=500, blank=True, null=True)
    companies = ArrayField(CharField(max_length=75), size=10, blank=True, null=True)

    def __str__(self) -> str:
        return self.name


class ProductionReservesBase(Model):
    """
    Abstract base model for production and reserves data.
    """

    METRIC_CHOICES = [
        ("kg", "Kilograms"),
        ("MT", "Metric Ton"),
        ("1000 MT", "1000 Metric Tons"),
        ("1 M. MT", "1 Million Metric Tons"),
        ("$ M.", "Million Dollars"),
        ("MCM", "Milion Cubic Meters"),
        ("Mct", "Million Carats"),
        ("Kct", "Thousands of Carats"),
    ]

    id = AutoField(primary_key=True)
    year = IntegerField()
    country = ForeignKey(Country, on_delete=CASCADE)
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    note = CharField(
        blank=True, null=True, max_length=100
    )  # extra note about type of production/reserves
    metric = CharField(max_length=50, choices=METRIC_CHOICES)
    amount = CharField(
        max_length=25
    )  # Char field needed because of fields like NA, Large, Small, ...

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
        max_digits=25,
        decimal_places=10,
    )
    share = DecimalField(
        validators=[non_negative_validator], max_digits=13, decimal_places=10
    )

    class Meta:
        abstract = True
        indexes = [
            Index(fields=["year", "country", "commodity"]),
        ]


class Reserves(ProductionReservesBase):
    """
    Model representing reserves data.
    """

    def __str__(self) -> str:
        return f"Reserves: {self.year} - {self.country} - {self.commodity}"

    class Meta:
        constraints = [
            UniqueConstraint(
                fields=["year", "country", "commodity"],
                name="unique_reserves_year_country_commodity",
            )
        ]


class Production(ProductionReservesBase):
    """
    Model representing production data.
    """

    def __str__(self) -> str:
        return f"Reserves: {self.year} - {self.country} - {self.commodity}"

    class Meta:
        constraints = [
            UniqueConstraint(
                fields=["year", "country", "commodity"],
                name="unique_production_year_country_commodity",
            )
        ]


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

    def __str__(self) -> str:
        return f"{self.year}: {self.commodity}"

    class Meta:
        indexes = [
            Index(fields=["year", "commodity"]),
        ]
        constraints = [
            UniqueConstraint(
                fields=["year", "commodity"],
                name="unique_year_commodity",
            )
        ]


class ImportData(ImportExportBase):
    """
    Model representing import data.
    """

    def __str__(self) -> str:
        return f"Import: {self.year} - {self.country} - {self.commodity}"

    class Meta:
        constraints = [
            UniqueConstraint(
                fields=["year", "country", "commodity"],
                name="unique_import_year_country_commodity",
            )
        ]


class ExportData(ImportExportBase):
    """
    Model representing export data.
    """

    def __str__(self) -> str:
        return f"Export: {self.year} - {self.country} - {self.commodity}"

    class Meta:
        constraints = [
            UniqueConstraint(
                fields=["year", "country", "commodity"],
                name="unique_export_year_country_commodity",
            )
        ]


class CommodityPrice(Model):
    """
    Model representing commodity prices.
    """

    id = AutoField(primary_key=True)
    commodity = ForeignKey(Commodity, on_delete=CASCADE)
    description = TextField(max_length=200, null=True, blank=True)
    date = DateField()
    price = DecimalField(
        validators=[non_negative_validator],
        max_digits=13,
        decimal_places=4,
    )

    def __str__(self) -> str:
        return f"{self.commodity}: {self.date}"

    class Meta:
        indexes = [
            Index(fields=["commodity"]),
        ]
        constraints = [
            UniqueConstraint(
                fields=["commodity", "date"],
                name="unique_commodity_date",
            )
        ]


# need more information for the following models
#   1.Climate
#   2.Companies
#   3.Investment into new production
#   4.General/Other Informations
#   5.Substitutes
