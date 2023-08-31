from api.models import Country

import json


def add_geojson():
    filename = "countries.geojson"
    with open(filename, "r") as geojson_file:
        geojson_data = json.load(geojson_file)

    # Assuming the GeoJSON file follows the standard structure
    if "features" in geojson_data and isinstance(geojson_data["features"], list):
        features = geojson_data["features"]
        for feature in features:
            country_name = feature["properties"]["ADMIN"]
            country = Country.objects.filter(name=country_name).first()
            if country:
                country.geojson = feature
                country.save()
