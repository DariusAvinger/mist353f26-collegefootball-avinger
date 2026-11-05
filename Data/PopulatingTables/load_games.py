"""
Load the Game table with 2025 and 2026 games from the CollegeFootballData.com API.

Run load_teams.py first: games are matched to rows already in Team.
Keep this file in the same folder as load_teams.py (it reuses its settings).

Setup:
    pip install requests pyodbc tzdata
"""
import json
import os
from datetime import datetime
from zoneinfo import ZoneInfo

import pyodbc
import requests

from load_teams import BASE_URL, CONFERENCES, CONN_STR, HEADERS, get_or_create_stadium

YEARS = [2025, 2026]
SEASON_TYPES = ["regular", "postseason"]
REFRESH_YEARS = {2026}  # in-progress season: re-download each run to pick up new scores
LOCAL_TZ = ZoneInfo("America/New_York")  # API times are UTC; store Eastern kickoff times


def pick(d, *keys):
    """Return the first key present (handles camelCase or snake_case responses)."""
    for k in keys:
        if k in d:
            return d[k]
    return None


def cached_get(path, params, cache_file, refresh=False):
    if os.path.exists(cache_file) and not refresh:
        with open(cache_file) as f:
            return json.load(f)
    resp = requests.get(f"{BASE_URL}{path}", headers=HEADERS, params=params, timeout=60)
    resp.raise_for_status()
    data = resp.json()
    with open(cache_file, "w") as f:
        json.dump(data, f, indent=2)
    return data


def main():
    conn = pyodbc.connect(CONN_STR)
    cur = conn.cursor()

    # Teams already in the database, keyed by school name
    cur.execute("SELECT TeamID, UniversityName, StadiumID FROM Team")
    teams = {name: (team_id, stadium_id) for team_id, name, stadium_id in cur.fetchall()}
    print(f"{len(teams)} teams in database")

    # Venue details (needed for neutral-site games), one API call
    venues = {v["id"]: v for v in cached_get("/venues", {}, "venues.json")}

    seen = set()
    inserted = updated = skipped = 0

    for year in YEARS:
        for season_type in SEASON_TYPES:
            for conf in CONFERENCES:
                games = cached_get(
                    "/games",
                    {"year": year, "seasonType": season_type, "conference": conf},
                    f"games_{year}_{season_type}_{conf}.json",
                    refresh=year in REFRESH_YEARS,
                )

                for g in games:
                    game_key = pick(g, "id")
                    if game_key in seen:  # e.g. SEC vs ACC appears in both lists
                        continue
                    seen.add(game_key)

                    home = teams.get(pick(g, "homeTeam", "home_team"))
                    away = teams.get(pick(g, "awayTeam", "away_team"))
                    if not home or not away:
                        skipped += 1  # opponent not in Team table (non-Power-4)
                        continue
                    home_id, home_stadium = home
                    away_id, _ = away

                    start = pick(g, "startDate", "start_date").replace("Z", "+00:00")
                    kickoff = datetime.fromisoformat(start).astimezone(LOCAL_TZ)
                    game_date = kickoff.date()
                    game_time = kickoff.time().replace(microsecond=0)

                    home_pts = pick(g, "homePoints", "home_points")
                    away_pts = pick(g, "awayPoints", "away_points")
                    winner = None
                    if home_pts is not None and away_pts is not None and home_pts != away_pts:
                        winner = home_id if home_pts > away_pts else away_id

                    venue = venues.get(pick(g, "venueId", "venue_id"))
                    stadium_id = get_or_create_stadium(cur, venue) if venue else home_stadium

                    cur.execute(
                        "SELECT GameID FROM Game WHERE HomeTeamID = ? AND AwayTeamID = ? AND GameDate = ?",
                        home_id, away_id, game_date,
                    )
                    row = cur.fetchone()
                    if row:
                        cur.execute(
                            "UPDATE Game SET GameTime = ?, HomeScore = ?, AwayScore = ?, "
                            "WinnerTeamID = ?, StadiumID = ? WHERE GameID = ?",
                            game_time, home_pts, away_pts, winner, stadium_id, row[0],
                        )
                        updated += 1
                    else:
                        cur.execute(
                            "INSERT INTO Game (GameDate, GameTime, HomeScore, AwayScore, "
                            "HomeTeamID, AwayTeamID, WinnerTeamID, StadiumID) "
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                            game_date, game_time, home_pts, away_pts,
                            home_id, away_id, winner, stadium_id,
                        )
                        inserted += 1

                conn.commit()
                print(f"{year} {season_type} {conf}: {len(games)} games fetched")

    cur.close()
    conn.close()
    print(f"Done. Inserted {inserted}, updated {updated}, skipped {skipped} (opponent not in Team).")


if __name__ == "__main__":
    main()
