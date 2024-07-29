from firebase_functions import https_fn
import firebase_admin
import json
from firebase_admin import firestore
from firebase_admin import credentials
from datetime import datetime, timedelta, time
import logging
import re
import requests

# Use your service account JSON file to initialize the Firebase Admin SDK
cred = credentials.Certificate("smart-garden-4cc8e-firebase-adminsdk-u0jg9-278f73f0b8.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore DB
db = firestore.client()

def to_water(index):
    current_ref = db.collection("pumps_commands").document("current_pump")
    response_data = current_ref.get().to_dict()
    response_data["array_pumps"][index] = True
    current_ref.set(response_data)

def plant_status():
    current_4_plants = db.collection("selected_plants").document("current")
    plant_ref = db.collection("garden_conditions").document("current")
    current_4_plants_doc = current_4_plants.get()
    current_4_plants_data = current_4_plants_doc.to_dict()
    plant_doc = plant_ref.get()
    if not plant_doc.exists:
        return https_fn.Response({"error": f"Document for plant '{plant_name}' not found"}, status=404)
    # Combine plant data and garden conditions into a single response
    response_data = plant_doc.to_dict()
    for i in range(len(current_4_plants_data["data"])):
        if i >= len(response_data["data"]):
            response_data["data"].append({"water": "unknown", "temperature": "unknown", "light": "unknown",
                                          "name": current_4_plants_data["data"][i]["name"]})
            continue
        elif current_4_plants_data["data"][i]["name"] is None:
            response_data["data"][i] = {"water": "no plant", "temperature": "no plant", "light": "no plant",
                                        "name": current_4_plants_data["data"][i]["name"]}
            continue
        plant_data = db.collection("plants").document(current_4_plants_data["data"][i]["name"]).get().to_dict()
        for key in ["water", "temperature", "light"]:
            if key == "water":
                if response_data["data"][i][key] > plant_data[key]["max"]:
                    response_data["data"][i][key] = "Too dry"
                elif response_data["data"][i][key] < plant_data[key]["min"]:
                    response_data["data"][i][key] = "Too wet"
                else:
                    response_data["data"][i][key] = "Good"
            elif key == "temperature":
                if response_data["data"][i][key] > plant_data[key]["max"]:
                    response_data["data"][i][key] = "Too high"
                elif response_data["data"][i][key] < plant_data[key]["min"]:
                    response_data["data"][i][key] = "Too low"
                else:
                    response_data["data"][i][key] = "Good"
            elif key == "light":
                if response_data["data"][i][key] > plant_data[key]["max"]:
                    response_data["data"][i][key] = "Too low"
                elif response_data["data"][i][key] < plant_data[key]["min"]:
                    response_data["data"][i][key] = "Too high"
                else:
                    response_data["data"][i][key] = "Good"

        response_data["data"][i]["name"] = current_4_plants_data["data"][i]["name"]
    response_data["water_tank"] = float(response_data["water_tank"])
    return response_data

@https_fn.on_request()
def set_data_from_garden(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response({"error": "Invalid request method"}, status=405)
    current_ref = db.collection("garden_conditions").document("current")
    timestamp = datetime.now().timestamp()
    # each timestamp containes all 4 plants sampels.
    data = req.get_json()
    water_tank = data.pop("water_tank")
    current_ref.set({**data, "timestamp":timestamp, "water_tank": water_tank})
    docs = db.collection("garden_conditions").stream()
    max_doc_id = None
    last_sample = None
    for doc in docs:
        doc_id = doc.id
        if doc_id == "current":
            continue
        if max_doc_id is None or float(doc_id) > max_doc_id:
            max_doc_id = float(doc_id)
            last_sample = doc
    if last_sample is None or not last_sample.exists or abs(timestamp -last_sample.to_dict().get("timestamp")) / 60 > 100 :
        garden_ref = db.collection("garden_conditions").document(str(timestamp))
        garden_ref.set({**data, "timestamp": timestamp})
    return https_fn.Response({"status": "Data saved successfully"}, status=200)



@https_fn.on_request()
def get_data_from_DB(req: https_fn.Request) -> https_fn.Response:
    # Extract plant name from query parameters
    plant_name = req.args.get('plant')
    if not plant_name:
        return https_fn.Response({"error": "Plant name is required"}, status=400)
    # Get a document reference for the plant
    plant_ref = db.collection("plants").document(plant_name)
    plant_doc = plant_ref.get()
    if not plant_doc.exists:
        return https_fn.Response({"error": f"Document for plant '{plant_name}' not found"}, status=404)

    # Combine plant data and garden conditions into a single response
    response_data = {
        "plant_data": plant_doc.to_dict(),
    }
    return https_fn.Response(json.dumps(response_data), mimetype='application/json')


# bring data from esp + give the 4 names of the plants that we chose
@https_fn.on_request()
def get_plants_current_data(req: https_fn.Request) -> https_fn.Response:
    response_data = plant_status()
    response_data["data"] = list(filter(lambda x: "name" in x, response_data["data"]))
    return https_fn.Response(json.dumps(response_data), mimetype='application/json')


# bring all the options to the UI
@https_fn.on_request()
def get_all_plants(req: https_fn.Request) -> https_fn.Response:
    docs = db.collection("plants").stream()
    selected_plants_from_before = db.collection("selected_plants").document("current").get().to_dict()
    plants = []
    for doc in docs:
        plants.append(doc.id)
    return https_fn.Response(json.dumps({"data" : plants,
                                         "selected": selected_plants_from_before["data"]
                                         }), mimetype='application/json')


# send to DB the 4 plants that are chosen
@https_fn.on_request()
def set_selected_plants(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response({"error": "Invalid request method"}, status=405)
    current_ref = db.collection("selected_plants").document("current")
    data = req.get_json()
    if len(current_ref.get().to_dict()["data"]) < min(4, len(data)):
        pump_off = db.collection("pumps_commands").document("current_pump")
        to_delete = pump_off.get().to_dict()
        for i in range(len(current_ref.get().to_dict()["data"]), min(4, len(data))):
            to_delete["array_pumps"][i] = False
        pump_off.set(to_delete)
    current_ref.set({"data": data})
    return https_fn.Response(status=200)

# get info for statistics
@https_fn.on_request()
def get_statistics(req: https_fn.Request) -> https_fn.Response:
    docs = db.collection("garden_conditions").stream()
    timestamps = [time_.id for time_ in docs if time_.id != "current"]
    timestamps.sort(key=float)
    current_list_of_timestamp = timestamps[:84]
    current_plants = db.collection("selected_plants").document("current")
    current_plants_doc = current_plants.get()
    current_plants_data = current_plants_doc.to_dict()
    plants = []
    for i, plant in enumerate(current_plants_data["data"]):
        plant_data = db.collection("plants").document(current_plants_data["data"][i]["name"]).get().to_dict()
        plants.append({"water":[], "temperature":[], "light": [],
                       "water_min": plant_data["water"]["min"],
                       "water_max": plant_data["water"]["max"],
                       "light_min": plant_data["light"]["min"],
                       "light_max": plant_data["light"]["max"],
                       "temperature_min": plant_data["temperature"]["min"],
                       "temperature_max": plant_data["temperature"]["max"]})

    # if we want less samples we need to change 84 in range
    for timestamp in current_list_of_timestamp:
        data = db.collection("garden_conditions").document(timestamp).get().to_dict()
        for index, plant in enumerate(data["data"]):
            if index >= len(current_plants_data["data"]):
                continue
            for key, value in plant.items():
                plants[index][key].append([timestamp, value])
    return https_fn.Response(json.dumps({"data" : plants}), mimetype='application/json')


# add a new plant that is not on the list
@https_fn.on_request()
def add_new_plant(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response({"error": "Invalid request method"}, status=405)
    data = req.get_json()
    current_ref = db.collection("plants").document(data["name"])
    plant_info = {}
    if data["water"] == "high amount of water":
        plant_info["water"] = {"min" : 2300, "max": 3200}
    elif data["water"] == "normal amount of water":
        plant_info["water"] = {"min": 3300, "max": 3800}
    else:
        plant_info["water"] = {"min": 3900, "max": 4095}

    if data["light"] == "high amount of light":
        plant_info["light"] = {"min" : 0, "max": 1200}
    elif data["light"] == "normal amount of light":
        plant_info["light"] = {"min": 0, "max": 1200}
    else:
        plant_info["light"] = {"min": 1250, "max": 2000}

    if data["temperature"] == "high temperature":
        plant_info["temperature"] = {"min" : 29, "max": 35}
    elif data["temperature"] == "normal temperature":
        plant_info["temperature"] = {"min": 25, "max": 28}
    else:
        plant_info["temperature"] = {"min": 19, "max": 24}

    current_ref.set(plant_info)
    return https_fn.Response(status=200)


# if we need to water the plant or not (get)
@https_fn.on_request()
def get_pump_command(req: https_fn.Request) -> https_fn.Response:
    status = plant_status()
    selected_plants = db.collection("selected_plants").document("current").get().to_dict()["data"]
    current_time = datetime.now().time()
    start_time = time(6,0) #06:00
    end_time = time(18, 0)  #18:00
    is_night = True
    is_raining_current = is_raining()
    if start_time <= current_time <=end_time:
        is_night = False
    for i, plant in enumerate(status["data"]):
        if selected_plants[i]["waterByWeather"] == True and is_raining_current:
            continue
        if selected_plants[i]["waterOnlyAtNight"] == True and is_night == False:
            continue
        if plant["water"] == "Too dry" and selected_plants[i]["pump"] == True:
            to_water(i)
    current_ref = db.collection("pumps_commands").document("current_pump")
    response_data = current_ref.get().to_dict()
    return https_fn.Response(json.dumps(response_data), mimetype='application/json')


# send to the esp commend to water the plants (manual)
@https_fn.on_request()
def send_pump_commend(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response({"error": "Invalid request method"}, status=405)
    data = req.get_json()
    to_water(data["pump_index"])
    return https_fn.Response(status=200)

# bring back the pump to "False":
@https_fn.on_request()
def stop_pump(req: https_fn.Request) -> https_fn.Response:
    if req.method != 'POST':
        return https_fn.Response({"error": "Invalid request method"}, status=405)
    current_ref = db.collection("pumps_commands").document("current_pump")
    response_data = current_ref.get().to_dict()
    for index, plant in enumerate(response_data["array_pumps"]):
        response_data["array_pumps"][index] = False
    current_ref.set(response_data)
    return https_fn.Response(status=200)

def is_raining():
    url = "http://api.weatherapi.com/v1/current.json"
    params = {
        'key': "enter_your_key",
        'q': "haifa",
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        cloud_coverage = data['current']['cloud']
        if cloud_coverage > 75:
            return True
    return False






