"""
Load Position, Roster, Player, PlayerPosition and PlayerStats for 2025 and 2026
from the CollegeFootballData.com API.

Keeps ONE player per position (QB, RB, WR, LB, CB, K) per team per season:
the team's statistical leader at that position.

Run load_teams.py first (players are attached to teams already in Team).
Keep this file in the same folder as load_teams.py and load_games.py.
"""
import re

import pyodbc

from load_games import REFRESH_YEARS, YEARS, cached_get, pick
from load_teams import CONFERENCES, CONN_STR

# Allowed by CK_Position (all are seeded; only KEEP_POSITIONS get players)
POSITIONS = ["QB", "RB", "WR", "TE", "OL", "DL", "LB", "CB", "S", "K", "P"]

# Which positions to keep, and the season stat that picks the one player: (category, statType)
KEEP_POSITIONS = {
    "QB": ("passing", "YDS"),
    "RB": ("rushing", "YDS"),
    "WR": ("receiving", "YDS"),
    "LB": ("defensive", "TOT"),
    "CB": ("defensive", "TOT"),
    "K": ("kicking", "FGM"),
}

# API position codes -> your position codes
POSITION_MAP = {
    "QB": "QB",
    "RB": "RB", "FB": "RB", "TB": "RB",
    "WR": "WR",
    "LB": "LB", "ILB": "LB", "OLB": "LB", "MLB": "LB",
    "CB": "CB", "DB": "CB",
    "K": "K", "PK": "K",
}


def upsert_roster(cur, team_id, year, wins, losses, ties):
    cur.execute("SELECT RosterID FROM Roster WHERE TeamID = ? AND RosterYear = ?", team_id, year)
    row = cur.fetchone()
    if row:
        cur.execute(
            "UPDATE Roster SET SeasonWins = ?, SeasonLosses = ?, SeasonTies = ? WHERE RosterID = ?",
            wins, losses, ties, row[0],
        )
        return row[0]
    cur.execute(
        "INSERT INTO Roster (RosterYear, SeasonWins, SeasonLosses, SeasonTies, TeamID) "
        "OUTPUT INSERTED.RosterID VALUES (?, ?, ?, ?, ?)",
        year, wins, losses, ties, team_id,
    )
    return cur.fetchone()[0]


def load_season_stats(year):
    """Return {(category, statType): {player_id: value}} for all four conferences."""
    lookup = {}
    for conf in CONFERENCES:
        rows = cached_get(
            "/stats/player/season",
            {"year": year, "conference": conf},
            f"playerstats_{year}_{conf}.json",
            refresh=year in REFRESH_YEARS,
        )
        for s in rows:
            key = (pick(s, "category"), pick(s, "statType", "stat_type"))
            player_id = str(pick(s, "playerId", "player_id"))
            try:
                value = float(pick(s, "stat"))
            except (TypeError, ValueError):
                continue
            lookup.setdefault(key, {})[player_id] = value
    return lookup


def main():
    conn = pyodbc.connect(CONN_STR)
    cur = conn.cursor()

    cur.execute("SELECT TeamID, UniversityName FROM Team")
    teams = {name: team_id for team_id, name in cur.fetchall()}
    print(f"{len(teams)} teams in database")

    # 1. Position
    for pos in POSITIONS:
        cur.execute(
            "IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = ?) "
            "INSERT INTO Position (PositionName) VALUES (?)",
            pos, pos,
        )
    conn.commit()
    cur.execute("SELECT PositionName, PositionID FROM Position")
    positions = {name: pid for name, pid in cur.fetchall()}

    # 2. Roster (team season + record)
    rosters = {}
    for year in YEARS:
        for conf in CONFERENCES:
            records = cached_get(
                "/records",
                {"year": year, "conference": conf},
                f"records_{year}_{conf}.json",
                refresh=year in REFRESH_YEARS,
            )
            for r in records:
                team_id = teams.get(pick(r, "team"))
                if not team_id:
                    continue
                total = pick(r, "total") or {}
                rosters[(team_id, year)] = upsert_roster(
                    cur, team_id, year,
                    total.get("wins") or 0, total.get("losses") or 0, total.get("ties") or 0,
                )
        conn.commit()
        print(f"{year}: records loaded")

    # Existing rows, so re-runs never add a second player at a position
    cur.execute("SELECT PlayerName, PlayerID FROM Player")
    players = {name.lower(): pid for name, pid in cur.fetchall()}
    cur.execute("SELECT PlayerID, PositionID FROM PlayerPosition")
    player_positions = {tuple(row) for row in cur.fetchall()}
    cur.execute(
        "SELECT ps.RosterID, pp.PositionID FROM PlayerStats ps "
        "JOIN PlayerPosition pp ON pp.PlayerID = ps.PlayerID"
    )
    filled = {tuple(row) for row in cur.fetchall()}  # (RosterID, PositionID) already taken

    # 3. Pick one player per position per team-season
    added = 0
    for year in YEARS:
        stats = load_season_stats(year)

        for school, team_id in teams.items():
            roster_id = rosters.get((team_id, year))
            if roster_id is None:
                roster_id = upsert_roster(cur, team_id, year, 0, 0, 0)
                rosters[(team_id, year)] = roster_id

            safe_name = re.sub(r"[^A-Za-z0-9]+", "_", school)
            people = cached_get(
                "/roster", {"team": school, "year": year}, f"roster_{year}_{safe_name}.json"
            )

            # Group roster by your position codes
            by_position = {}
            for p in people:
                pos = POSITION_MAP.get((pick(p, "position") or "").upper())
                if pos in KEEP_POSITIONS:
                    by_position.setdefault(pos, []).append(p)

            chosen = []
            for pos, candidates in by_position.items():
                if (roster_id, positions[pos]) in filled:
                    continue
                metric = stats.get(KEEP_POSITIONS[pos], {})
                # Leader by the stat; ties (or no stats yet) fall back to roster order
                best = max(candidates, key=lambda p: metric.get(str(pick(p, "id")), 0))
                chosen.append((pos, best))

            for pos, p in chosen:
                first = (pick(p, "firstName", "first_name") or "").strip()
                last = (pick(p, "lastName", "last_name") or "").strip()
                name = f"{first} {last}".strip()[:100]
                if not name:
                    continue

                player_id = players.get(name.lower())
                if player_id is None:
                    cur.execute(
                        "INSERT INTO Player (PlayerName) OUTPUT INSERTED.PlayerID VALUES (?)", name
                    )
                    player_id = cur.fetchone()[0]
                    players[name.lower()] = player_id

                key = (player_id, positions[pos])
                if key not in player_positions:
                    cur.execute("INSERT INTO PlayerPosition (PlayerID, PositionID) VALUES (?, ?)", *key)
                    player_positions.add(key)

                cur.execute(
                    "IF NOT EXISTS (SELECT 1 FROM PlayerStats WHERE PlayerID = ? AND RosterID = ?) "
                    "INSERT INTO PlayerStats (PlayerID, RosterID) VALUES (?, ?)",
                    player_id, roster_id, player_id, roster_id,
                )
                filled.add((roster_id, positions[pos]))
                added += 1

            conn.commit()
            print(f"{year} {school}: " + ", ".join(f"{pos} {pick(p, 'lastName', 'last_name')}" for pos, p in chosen))

    cur.close()
    conn.close()
    print(f"Done. {added} player-season rows added.")


if __name__ == "__main__":
    main()
