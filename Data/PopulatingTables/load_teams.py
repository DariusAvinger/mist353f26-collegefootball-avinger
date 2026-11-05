"""
Load Conference, Stadium, and Team tables from the CollegeFootballData.com API.

Setup:
    pip install requests pyodbc
    CFBD_API_KEY
    CONN_STR
"""
import json
import os

import pyodbc
import requests

CONN_STR = (
    "Driver={ODBC Driver 18 for SQL Server};"
    "Server=;"
    "Database=;"
    "Uid=;"
    "Pwd=;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
)

API_KEY = ""

BASE_URL = "https://api.collegefootballdata.com"
HEADERS = {"Authorization": f"Bearer {API_KEY}", "Accept": "application/json"}

# The API filters by conference ABBREVIATION
CONFERENCES = ["SEC", "B1G", "B12", "ACC"]
YEAR = 2026  # season whose conference membership you want

SAVE_RAW_JSON = True  # keep a local copy so re-runs don't spend API calls


def fetch_teams(conference):
    cache_file = f"teams_{conference}_{YEAR}.json"
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            return json.load(f)

    resp = requests.get(
        f"{BASE_URL}/teams",
        headers=HEADERS,
        params={"conference": conference, "year": YEAR},
        timeout=30,
    )
    resp.raise_for_status()
    data = resp.json()

    if SAVE_RAW_JSON:
        with open(cache_file, "w") as f:
            json.dump(data, f, indent=2)
    return data


def get_or_create_conference(cur, name):
    cur.execute("SELECT ConferenceID FROM Conference WHERE ConferenceName = ?", name)
    row = cur.fetchone()
    if row:
        return row[0]
    cur.execute(
        "INSERT INTO Conference (ConferenceName) OUTPUT INSERTED.ConferenceID VALUES (?)",
        name,
    )
    return cur.fetchone()[0]


def get_or_create_stadium(cur, loc):
    name = (loc.get("name") or "Unknown Stadium")[:50]
    city = (loc.get("city") or "Unknown")[:50]
    state = (loc.get("state") or "NA")[:2]
    capacity = loc.get("capacity") or 0
    field = "Grass" if loc.get("grass") else "Artificial Turf"

    cur.execute(
        "SELECT StadiumID FROM Stadium "
        "WHERE StadiumName = ? AND StadiumCity = ? AND StadiumState = ?",
        name, city, state,
    )
    row = cur.fetchone()
    if row:
        return row[0]
    cur.execute(
        "INSERT INTO Stadium (StadiumName, StadiumCity, StadiumState, StadiumCapacity, TypeOfField) "
        "OUTPUT INSERTED.StadiumID VALUES (?, ?, ?, ?, ?)",
        name, city, state, capacity, field,
    )
    return cur.fetchone()[0]


def insert_team(cur, university, mascot, stadium_id, conference_id):
    cur.execute("SELECT TeamID FROM Team WHERE UniversityName = ?", university)
    if cur.fetchone():
        return False  # already loaded
    cur.execute(
        "INSERT INTO Team (UniversityName, TeamName, StadiumID, ConferenceID) VALUES (?, ?, ?, ?)",
        university, mascot, stadium_id, conference_id,
    )
    return True


def main():
    conn = pyodbc.connect(CONN_STR)
    cur = conn.cursor()

    for conf in CONFERENCES:
        teams = fetch_teams(conf)
        print(f"{conf}: {len(teams)} teams returned")

        for t in teams:
            conf_name = t.get("conference") or conf  # e.g. "Big Ten" rather than "B1G"
            conference_id = get_or_create_conference(cur, conf_name[:50])
            stadium_id = get_or_create_stadium(cur, t.get("location") or {})
            added = insert_team(
                cur,
                t["school"][:50],
                (t.get("mascot") or t["school"])[:50],
                stadium_id,
                conference_id,
            )
            print(f"   {'added' if added else 'skipped'}: {t['school']}")

        conn.commit()

    cur.close()
    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
