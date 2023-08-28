# source for flags: # https://github.com/hampusborgos/country-flags/tree/main

from datetime import datetime
import ast

from django.shortcuts import get_object_or_404
from django.utils.text import slugify
import pandas as pd

from api.models import Country, Commodity, CommodityPrice


class BizDataLoader:
    MONTHS = {
        "M1": 1,
        "M2": 2,
        "M3": 3,
        "M4": 4,
        "M5": 5,
        "M6": 6,
        "M7": 7,
        "M8": 8,
        "M9": 9,
        "M10": 10,
        "M11": 11,
        "M12": 12,
    }

    @staticmethod
    def add_country_data():
        filename = "ease_of_biz_and_income_group.csv"
        with open(filename, "r", newline="") as csv_file:
            data_frame = pd.read_csv(csv_file)
            countries = data_frame["Country"].tolist()
            business_ranking = data_frame["BusinessRanking"].tolist()
            income_group = data_frame["IncomeGroup"].tolist()
            for i in range(len(countries)):
                country = Country.objects.filter(name=countries[i].rstrip()).first()
                if country:
                    country.flag_path = f"flags/{slugify(country.name)}"
                    if str(business_ranking[i]) != "nan":
                        country.ease_of_biz = business_ranking[i]
                    country.income_group = income_group[i]
                    country.save()

    @staticmethod
    def add_price_data():
        data = pd.read_csv("commodity_prices.csv", header=None, index_col=None)
        data_frame = data.transpose()
        data_dict = {}
        for name in data_frame.columns:
            column_data = data_frame[name].tolist()
            data_dict[column_data[0]] = column_data[1:]
        commodities = data_dict["Commodity"]
        descriptions = data_dict["Description"]
        for key, prices in data_dict.items():
            if key not in ["Commodity", "Description"]:
                year = int(key[:4])
                month_string = key[4:]
                month = BizDataLoader.MONTHS[month_string]
                date_obj = datetime(year, month, 1)
                date = date_obj.strftime("%Y-%m-%d")
                for i in range(len(prices)):
                    commodity = Commodity.objects.filter(
                        name=commodities[i].rstrip()
                    ).first()
                    if str(prices[i]) != "nan" and commodity:
                        CommodityPrice.objects.create(
                            commodity=commodity,
                            description=descriptions[i],
                            date=date,
                            price=prices[i],
                        )

    @staticmethod
    def add_commodity_images():
        for commodity in Commodity.objects.all():
            commodity.img_path = f"commodity_imgs/{slugify(commodity.name)}"
            commodity.save()

    @staticmethod
    def add_commodity_info_and_companies():
        with open("commodity_data.csv", "r", newline="") as csv_file:
            data_frame = pd.read_csv(csv_file)
            commodity_column = data_frame["Commodity"].tolist()
            info_column = data_frame["Info"].tolist()
            companies_column = data_frame["Companies"].tolist()
            for i in range(len(commodity_column)):
                commodity = get_object_or_404(Commodity, name=commodity_column[i])
                commodity.info = info_column[i]
                commodity.companies = ast.literal_eval(companies_column[i])
                commodity.save()


if __name__ == "__main__":
    loader = BizDataLoader()
    loader.add_country_data()
    loader.add_price_data()
    loader.add_commodity_images()
    loader.add_commodity_info_and_companies()
