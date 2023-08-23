# source for flags: # https://github.com/hampusborgos/country-flags/tree/main

from django.utils.text import slugify
from django.shortcuts import get_object_or_404
import pandas as pd

from api.models import Country


class BizDataLoader:
    NEW_COUNTRIES = [
        "Aruba",
        "American Samoa",
        "Bermuda",
        "Channel Islands",
        "Curacao",
        "Cayman Islands",
        "Faroe Islands",
        "Gibraltar",
        "Guam",
        "Hong Kong",
        "Isle of Man",
        "St. Kitts and Nevis",
        "St. Lucia",
        "Macao",
        "St. Martin",
        "Northern Mariana Islands",
        "Puerto Rico",
        "West Bank and Gaza",
        "French Polynesia",
        "Sint Maarten",
        "Turks and Caicos Islands",
        "St. Vincent and the Grenadines",
        "Virgin Islands",
        "Kosovo",
    ]

    @staticmethod
    def create_new_countries():
        for country in BizDataLoader.NEW_COUNTRIES:
            Country.objects.create(name=country)

    @staticmethod
    def add_country_data():
        filename = "ease_of_biz_and_income_group.csv"
        with open(filename, "r", newline="") as csv_file:
            data_frame = pd.read_csv(csv_file)
            countries = data_frame["Country"].tolist()
            business_ranking = data_frame["BusinessRanking"].tolist()
            income_group = data_frame["IncomeGroup"].tolist()
            for i in range(len(countries)):
                print(countries[i])
                country = get_object_or_404(Country, name=countries[i].rstrip())
                country.flag_path = f"flags/{slugify(country.name)}"
                print(business_ranking[i])
                if str(business_ranking[i]) != "nan":
                    print("if")
                    country.ease_of_biz = business_ranking[i]
                country.income_group = income_group[i]
                country.save()


if __name__ == "__main__":
    loader = BizDataLoader()
    loader.create_new_countries()
    loader.add_country_data()
