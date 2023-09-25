from api.models import Country


def add_new_countries():
    countries = [
        "Kosovo",
        "Faroe Islands",
        "Somaliland",
        "Puerto Rico",
        "Western Sahara",
        "Northern Cyprus",
        "Cayman Islands",
        "Virgin Islands",
        "Montserrat",
        "Anguilla",
        "Aruba",
        "Curacao",
    ]

    for country in countries:
        Country.objects.create(name=country)


# 1.add_new_countries
# 2.biz_data_loader => add_country_data
# 3.geojson_loader
