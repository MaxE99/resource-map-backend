import os
import pandas as pd

from api.models import Commodity, Country, GovInfo, Production, Reserves
from django.shortcuts import get_object_or_404


class GovDataLoader(object):
    folder_path = "gov_resources_data"
    TEXTUAL_INFORMATION = [
        "Metric",
        "Domestic Production and Use:",
        "Recycling:",
        "Events, Trends, and Issues:",
        "World Resources:",
        "Substitutes:",
    ]
    COUNTRIES = [
        "Afghanistan",
        "Albania",
        "Algeria",
        "Andorra",
        "Angola",
        "Antigua and Barbuda",
        "Argentina",
        "Armenia",
        "Australia",
        "Austria",
        "Azerbaijan",
        "Bahamas",
        "Bahrain",
        "Bangladesh",
        "Barbados",
        "Belarus",
        "Belgium",
        "Belize",
        "Benin",
        "Bhutan",
        "Bolivia",
        "Bosnia and Herzegovina",
        "Botswana",
        "Brazil",
        "Brunei",
        "Bulgaria",
        "Burkina Faso",
        "Burundi",
        "Cabo Verde",
        "Cambodia",
        "Cameroon",
        "Canada",
        "Central African Republic",
        "Chad",
        "Chile",
        "China",
        "Colombia",
        "Comoros",
        "Congo",
        "Costa Rica",
        "Croatia",
        "Cuba",
        "Cyprus",
        "Czechia",
        "Democratic Republic of the Congo",
        "Denmark",
        "Djibouti",
        "Dominica",
        "Dominican Republic",
        "Ecuador",
        "Egypt",
        "El Salvador",
        "Equatorial Guinea",
        "Eritrea",
        "Estonia",
        "Eswatini",
        "Ethiopia",
        "Fiji",
        "Finland",
        "France",
        "Gabon",
        "Gambia",
        "Georgia",
        "Germany",
        "Ghana",
        "Greece",
        "Greenland",
        "Grenada",
        "Guadeloupe",
        "Guatemala",
        "Guinea",
        "Guinea-Bissau",
        "Guyana",
        "Haiti",
        "Holy See",
        "Honduras",
        "Hungary",
        "Iceland",
        "India",
        "Indonesia",
        "Iran",
        "Iraq",
        "Ireland",
        "Israel",
        "Italy",
        "Ivory Coast",
        "Jamaica",
        "Japan",
        "Jordan",
        "Kazakhstan",
        "Kenya",
        "Kiribati",
        "Kuwait",
        "Kyrgyzstan",
        "Laos",
        "Latvia",
        "Lebanon",
        "Lesotho",
        "Liberia",
        "Libya",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Madagascar",
        "Malawi",
        "Malaysia",
        "Maldives",
        "Mali",
        "Malta",
        "Marshall Islands",
        "Mauritania",
        "Mauritius",
        "Mexico",
        "Micronesia",
        "Moldova",
        "Monaco",
        "Mongolia",
        "Montenegro",
        "Morocco",
        "Mozambique",
        "Myanmar",
        "Namibia",
        "Nauru",
        "Nepal",
        "Netherlands",
        "New Caledonia",
        "New Zealand",
        "Nicaragua",
        "Niger",
        "Nigeria",
        "North Korea",
        "North Macedonia",
        "Norway",
        "Oman",
        "Pakistan",
        "Palau",
        "Palestine State",
        "Panama",
        "Papua New Guinea",
        "Paraguay",
        "Peru",
        "Philippines",
        "Poland",
        "Portugal",
        "Qatar",
        "Romania",
        "Russia",
        "Rwanda",
        "Saint Kitts and Nevis",
        "Saint Lucia",
        "Saint Vincent and the Grenadines",
        "Samoa",
        "San Marino",
        "Sao Tome and Principe",
        "Saudi Arabia",
        "Senegal",
        "Serbia",
        "Seychelles",
        "Sierra Leone",
        "Singapore",
        "Slovakia",
        "Slovenia",
        "Solomon Islands",
        "Somalia",
        "South Africa",
        "South Korea",
        "South Sudan",
        "Spain",
        "Sri Lanka",
        "Sudan",
        "Suriname",
        "Sweden",
        "Switzerland",
        "Syria",
        "Taiwan",
        "Tajikistan",
        "Tanzania",
        "Thailand",
        "Timor-Leste",
        "Togo",
        "Tonga",
        "Trinidad and Tobago",
        "Tunisia",
        "Turkey",
        "Turkmenistan",
        "Tuvalu",
        "Uganda",
        "Ukraine",
        "United Arab Emirates",
        "United Kingdom",
        "United States",
        "Uruguay",
        "Uzbekistan",
        "Vanuatu",
        "Venezuela",
        "Vietnam",
        "Yemen",
        "Zambia",
        "Zimbabwe",
        "Other countries",
        "World total",
    ]

    def create_commodities(self):
        for filename in os.listdir(self.folder_path):
            removed_prefix = filename.split("-", 1)[1]
            removed_suffix = removed_prefix.split(".pdf.csv")[0]
            split_names = removed_suffix.split("-")
            commodity_name = " ".join([part.capitalize() for part in split_names])
            if not Commodity.objects.filter(name=commodity_name):
                Commodity.objects.create(name=commodity_name)

    def create_countries(self):
        for country in self.COUNTRIES:
            Country.objects.create(name=country)

    def create_gov_data(self):
        for filename in os.listdir(self.folder_path):
            prefix = filename.split("-")[0]
            removed_prefix = filename.split("-", 1)[1]
            removed_suffix = removed_prefix.split(".pdf.csv")[0]
            split_names = removed_suffix.split("-")
            commodity_name = " ".join([part.capitalize() for part in split_names])
            year = prefix.replace("mcs", "")
            with open(
                os.path.join(self.folder_path, filename), "r", newline=""
            ) as csv_file:
                data_frame = pd.read_csv(csv_file)
                textual_info = data_frame.loc[0, self.TEXTUAL_INFORMATION]
                prod_and_use = textual_info["Domestic Production and Use:"]
                recycling = textual_info["Recycling:"]
                events = textual_info["Events, Trends, and Issues:"]
                world_resources = textual_info["World Resources:"]
                substitutes = textual_info["Substitutes:"]
                commodity = get_object_or_404(Commodity, name=commodity_name)
                GovInfo.objects.create(
                    year=year,
                    commodity=commodity,
                    prod_and_use=prod_and_use,
                    recycling=recycling,
                    events=events,
                    world_resources=world_resources,
                    substitutes=substitutes,
                )
                if "Country" in data_frame.columns and "Metric" in data_frame.columns:
                    metric = textual_info["Metric"]
                    column_names = data_frame.columns.tolist()
                    countries = data_frame["Country"].dropna().tolist()
                    for column in column_names:
                        if column.startswith("Reserves") or column.startswith(
                            "Production"
                        ):
                            model_class = (
                                Reserves
                                if column.startswith("Reserves")
                                else Production
                            )
                            values = data_frame[column].tolist()
                            if len(values) - 1 != len(countries):
                                print(filename)
                                raise Exception("These should have the same length!")
                            year = values[0]
                            note = None
                            if "-" in column:
                                note = column.split("-")[-1].split(".")[0]
                            values = values[1:]
                            for i in range(len(countries)):
                                if countries[i].startswith("World total"):
                                    country = get_object_or_404(
                                        Country, name="World total"
                                    )
                                else:
                                    country = get_object_or_404(
                                        Country, name=countries[i]
                                    )
                                instance = model_class.objects.filter(
                                    year=year, country=country, commodity=commodity
                                ).first()
                                if instance:
                                    instance.amount = values[i]
                                    instance.save()
                                else:
                                    model_class.objects.create(
                                        year=year,
                                        country=country,
                                        commodity=commodity,
                                        note=note,
                                        metric=metric,
                                        amount=values[i],
                                    )


if __name__ == "__main__":
    loader = GovDataLoader()
    loader.create_countries()
    loader.create_commodities()
    loader.create_gov_data()
