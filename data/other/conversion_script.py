# import json
# import os
# from decimal import Decimal
# from datetime import date

# from django.db.models import (
#     AutoField,
#     BigIntegerField,
#     CASCADE,
#     CharField,
#     DateField,
#     DecimalField,
#     ForeignKey,
#     Index,
#     IntegerField,
#     JSONField,
#     Model,
#     TextField,
#     UniqueConstraint,
# )
# from django.contrib.postgres.fields import ArrayField
# from django.core.exceptions import ValidationError


# def non_negative_validator(value):
#     """
#     Validator function to ensure that the given value is non-negative.

#     Args:
#         value (float or int): The value to be validated.

#     Raises:
#         ValidationError: If the value is negative.
#     """
#     if value < 0:
#         raise ValidationError("This value must be non-negative.")


# class Country(Model):
#     """
#     A model representing a country.
#     """

#     INCOME_CHOICES = [
#         ("High income", "High income"),
#         ("Upper middle income", "Upper middle income"),
#         ("Lower middle income", "Lower middle income"),
#         ("Low income", "Low income"),
#     ]

#     id = AutoField(primary_key=True)
#     name = CharField(unique=True, max_length=100)
#     flag_path = CharField(
#         max_length=500, blank=True
#     )  # the link to the flag of the country
#     ease_of_biz = DecimalField(
#         blank=True,
#         null=True,
#         max_digits=4,
#         decimal_places=1,
#         validators=[non_negative_validator],
#     )  # ease of doing business index
#     income_group = CharField(
#         blank=True, null=True, max_length=50, choices=INCOME_CHOICES
#     )
#     gdp = BigIntegerField(blank=True, null=True, validators=[non_negative_validator])
#     geojson = JSONField(null=True, blank=True)

#     class Meta:
#         ordering = ["name"]

#     def __str__(self) -> str:
#         return self.name


# class Commodity(Model):
#     """
#     Model representing a commodity.
#     """

#     id = AutoField(primary_key=True)
#     name = CharField(unique=True, max_length=100)
#     info = TextField(blank=True, null=True)
#     img_path = CharField(max_length=500, blank=True, null=True)
#     companies = ArrayField(CharField(max_length=75), size=10, blank=True, null=True)

#     def __str__(self) -> str:
#         return self.name


# class HarvardCountry(Model):
#     """
#     Model representing a country from the harvard csvs
#     """

#     harvard_id = AutoField(primary_key=True)
#     country_id = ForeignKey(Country, on_delete=CASCADE)
#     name = CharField(unique=True, max_length=100)


# class HarvardCommodity(Model):
#     """
#     Model representing a commodity from the harvard csvs
#     """

#     harvard_id = AutoField(primary_key=True)
#     commodity_id = ForeignKey(Commodity, on_delete=CASCADE)
#     name = CharField(unique=True, max_length=100)


# class ProductionReservesBase(Model):
#     """
#     Abstract base model for production and reserves data.
#     """

#     METRIC_CHOICES = [
#         ("kg", "Kilograms"),
#         ("MT", "Metric Ton"),
#         ("1000 MT", "1000 Metric Tons"),
#         ("1 M. MT", "1 Million Metric Tons"),
#         ("$ M.", "Million Dollars"),
#         ("MCM", "Milion Cubic Meters"),
#         ("Mct", "Million Carats"),
#         ("Kct", "Thousands of Carats"),
#     ]

#     id = AutoField(primary_key=True)
#     year = IntegerField()
#     country = ForeignKey(Country, on_delete=CASCADE)
#     commodity = ForeignKey(Commodity, on_delete=CASCADE)
#     note = CharField(
#         blank=True, null=True, max_length=100
#     )  # extra note about type of production/reserves
#     metric = CharField(max_length=50, choices=METRIC_CHOICES)
#     amount = CharField(
#         max_length=25
#     )  # Char field needed because of fields like NA, Large, Small, ...
#     rank = IntegerField(
#         null=True,
#         blank=True,
#     )
#     share = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=13,
#         decimal_places=10,
#         null=True,
#         blank=True,
#     )

#     class Meta:
#         abstract = True
#         indexes = [
#             Index(fields=["year", "country", "commodity"]),
#         ]


# class ImportExportBase(Model):
#     """
#     Abstract base model for import and export data.
#     """

#     id = AutoField(primary_key=True)
#     year = IntegerField()
#     country = ForeignKey(HarvardCountry, on_delete=CASCADE)
#     commodity = ForeignKey(HarvardCommodity, on_delete=CASCADE)
#     amount = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=25,
#         decimal_places=10,
#     )
#     share = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=13,
#         decimal_places=10,
#     )

#     class Meta:
#         abstract = True
#         indexes = [
#             Index(fields=["year", "country", "commodity"]),
#         ]


# class Reserves(ProductionReservesBase):
#     """
#     Model representing reserves data.
#     """

#     def __str__(self) -> str:
#         return f"Reserves: {self.year} - {self.country} - {self.commodity}"

#     class Meta:
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "country", "commodity"],
#                 name="unique_reserves_year_country_commodity",
#             )
#         ]


# class Production(ProductionReservesBase):
#     """
#     Model representing production data.
#     """

#     def __str__(self) -> str:
#         return f"Production: {self.year} - {self.country} - {self.commodity}"

#     class Meta:
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "country", "commodity"],
#                 name="unique_production_year_country_commodity",
#             )
#         ]


# class GovInfo(Model):
#     """
#     Model representing United States government information about commodities.
#     """

#     id = AutoField(primary_key=True)
#     year = IntegerField()
#     commodity = ForeignKey(Commodity, on_delete=CASCADE)
#     prod_and_use = TextField()  # domnestic production and use
#     recycling = TextField()
#     events = TextField()  # events, trends and issues
#     world_resources = TextField()
#     substitutes = TextField()

#     def __str__(self) -> str:
#         return f"{self.year}: {self.commodity}"

#     class Meta:
#         indexes = [
#             Index(fields=["year", "commodity"]),
#         ]
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "commodity"],
#                 name="unique_year_commodity",
#             )
#         ]


# class ImportData(ImportExportBase):
#     """
#     Model representing import data.
#     """

#     def __str__(self) -> str:
#         return f"Import: {self.year} - {self.country} - {self.commodity}"

#     class Meta:
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "country", "commodity"],
#                 name="unique_import_year_country_commodity",
#             )
#         ]


# class ExportData(ImportExportBase):
#     """
#     Model representing export data.
#     """

#     def __str__(self) -> str:
#         return f"Export: {self.year} - {self.country} - {self.commodity}"

#     class Meta:
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "country", "commodity"],
#                 name="unique_export_year_country_commodity",
#             )
#         ]


# class CommodityPrice(Model):
#     """
#     Model representing commodity prices.
#     """

#     id = AutoField(primary_key=True)
#     commodity = ForeignKey(Commodity, on_delete=CASCADE)
#     description = TextField(max_length=200, null=True, blank=True)
#     date = DateField()
#     price = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=13,
#         decimal_places=4,
#     )

#     def __str__(self) -> str:
#         return f"{self.commodity}: {self.date}"

#     class Meta:
#         indexes = [
#             Index(fields=["commodity"]),
#         ]
#         constraints = [
#             UniqueConstraint(
#                 fields=["commodity", "date"],
#                 name="unique_commodity_date",
#             )
#         ]


# class ImportExportBalance(Model):
#     """
#     Model representing data related to the import/export balance of a country.
#     """

#     id = AutoField(primary_key=True)
#     year = IntegerField()
#     country = ForeignKey(Country, on_delete=CASCADE)
#     total_imports = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=30,
#         decimal_places=10,
#     )
#     total_exports = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=30,
#         decimal_places=10,
#     )
#     total_commodity_imports = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=30,
#         decimal_places=10,
#     )
#     total_commodity_exports = DecimalField(
#         validators=[non_negative_validator],
#         max_digits=30,
#         decimal_places=10,
#     )

#     def __str__(self) -> str:
#         return f"ImportExportBalance: {self.year} - {self.country}"

#     class Meta:
#         constraints = [
#             UniqueConstraint(
#                 fields=["year", "country"],
#                 name="unique_year_country_balance",
#             )
#         ]


# def get_field_value(instance, field):
#     value = getattr(instance, field.name)
#     if isinstance(value, Decimal) or isinstance(value, date):
#         return str(value)
#     return value


# def serialize_date(date_obj):
#     return date_obj.isoformat() if isinstance(date_obj, date) else date_obj


# def write_to_json(filename, data):
#     with open(filename, "a") as file:
#         for entry in data:
#             json.dump(entry, file, indent=4)
#             file.write(",\n")


# def write_production_to_json(filename):
#     data = []
#     for instance in Production.objects.all():
#         instance_data = {
#             "pk": "type=Production?commodity={}?country={}".format(
#                 instance.commodity.name, instance.country.name
#             ),
#             "sk": instance.year,
#             "type": "Production",
#             "type_and_country": "type=Production?country={}".format(
#                 instance.country.name
#             ),
#             "type_and_commodity": "type=Production?commodity={}".format(
#                 instance.commodity.name
#             ),
#             "data": {
#                 str(field.name): (
#                     get_field_value(instance, field)
#                     if not isinstance(field, ForeignKey)
#                     else str(getattr(instance, field.name))
#                 )
#                 for field in instance._meta.fields
#             },
#         }
#         data.append(instance_data)
#     write_to_json(filename, data)


# def write_reserves_to_json(filename):
#     data = []
#     for instance in Reserves.objects.all():
#         instance_data = {
#             "pk": "type=Reserves?commodity={}?country={}".format(
#                 instance.commodity.name, instance.country.name
#             ),
#             "sk": instance.year,
#             "type_and_country": "type=Reserves?country={}".format(
#                 instance.country.name
#             ),
#             "type_and_commodity": "type=Reserves?commodity={}".format(
#                 instance.commodity.name
#             ),
#             "data": {
#                 str(field.name): (
#                     get_field_value(instance, field)
#                     if not isinstance(field, ForeignKey)
#                     else str(getattr(instance, field.name))
#                 )
#                 for field in instance._meta.fields
#             },
#         }
#         data.append(instance_data)
#     write_to_json(filename, data)


# def write_price_data_to_json(filename):
#     price_dict = {}
#     for instance in CommodityPrice.objects.all():
#         commodity = instance.commodity.name
#         if not commodity in price_dict:
#             price_dict[commodity] = []
#         price_dict[commodity].append(
#             {
#                 str(field.name): (
#                     get_field_value(instance, field)
#                     if not isinstance(field, ForeignKey)
#                     else str(getattr(instance, field.name))
#                 )
#                 for field in instance._meta.fields
#             }
#         )
#     data_list = []
#     for commodity, data in price_dict.items():
#         instance_data = {
#             "pk": "type=Prices?commodity={}".format(commodity),
#             "sk": 0,
#             "data": data,
#         }
#         data_list.append(instance_data)
#     write_to_json(filename, data_list)


# def write_gov_info_data_to_json(filename):
#     data = []
#     for instance in GovInfo.objects.all():
#         instance_data = {
#             "pk": "type=Govinfo?commodity={}".format(instance.commodity.name),
#             "sk": instance.year,
#             "data": {
#                 str(field.name): (
#                     get_field_value(instance, field)
#                     if not isinstance(field, ForeignKey)
#                     else str(getattr(instance, field.name))
#                 )
#                 for field in instance._meta.fields
#             },
#         }
#         data.append(instance_data)
#     write_to_json(filename, data)


# def write_import_export_balance_to_json(filename):
#     data = []
#     for instance in ImportExportBalance.objects.all():
#         instance_data = {
#             "pk": "type=Balance?country={}".format(instance.country.name),
#             "sk": instance.year,
#             "type": "Balance",
#             "data": {
#                 str(field.name): (
#                     get_field_value(instance, field)
#                     if not isinstance(field, ForeignKey)
#                     else str(getattr(instance, field.name))
#                 )
#                 for field in instance._meta.fields
#             },
#         }
#         data.append(instance_data)
#     write_to_json(filename, data)


# def create_nosql_db():
#     filename = "nosql_db.json"
#     if not os.path.exists(filename):
#         with open(filename, "w"):
#             pass

#     write_production_to_json(filename)
#     write_reserves_to_json(filename)
#     write_price_data_to_json(filename)
#     write_gov_info_data_to_json(filename)
#     write_import_export_balance_to_json(filename)
