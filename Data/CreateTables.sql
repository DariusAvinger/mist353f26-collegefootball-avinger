







if object_id('PUNTERSTATS') is not null drop table PUNTERSTATS;
if object_id('KICKERSTATS') is not null drop table KICKERSTATS;
if object_id('RETURNERSTATS') is not null drop table RETURNERSTATS;
if object_id('DEFENDERSTATS') is not null drop table DEFENDERSTATS;
if object_id('RBSTATS') is not null drop table RBSTATS;
if object_id('QBSTATS') is not null drop table QBSTATS;
if object_id('PLAYERSTATS') is not null drop table PLAYERSTATS;
if object_id('PLAYERPOSITION') is not null drop table PLAYERPOSITION;
if object_id('POSITION') is not null drop table POSITION;
if object_id('PLAYER') is not null drop table PLAYER;
if object_id('COACHROSTER') is not null drop table COACHROSTER;
if object_id('COACH') is not null drop table COACH;
if object_id('ROSTER') is not null drop table ROSTER;
if object_id('WEEKLYPREDICTIONRESULTS') is not null drop table WEEKLYPREDICTIONRESULTS;
if object_id('GAMEPREDICTION') is not null drop table GAMEPREDICTION;
if object_id('APPUSERTEAM') is not null drop table APPUSERTEAM;
if object_id('APPUSER') is not null drop table APPUSER;
if object_id('GAME') is not null drop table GAME;
if object_id('TEAM') is not null drop table TEAM;
if object_id('CONFERENCE') is not null drop table CONFERENCE;
if object_id('STADIUM') is not null drop table STADIUM;

go


create table STADIUM (
    StadiumID INT NOT NULL IDENTITY(1,1),
    StadiumName VARCHAR(100) NOT NULL,
    StadiumStreet VARCHAR(100) NOT NULL,
    StadiumCity VARCHAR(50) NOT NULL,
    StadiumState CHAR(2) NOT NULL,
    StadiumCapacity INT NOT NULL,
    TypeOfField VARCHAR(50) NOT NULL,
    constraint PK_Stadium Primary Key (StadiumID),
    constraint CK_TypeOfField CHECK (TypeOfField IN ('Grass', 'Artificial Turf'))
);

go

create table CONFERENCE (
    ConferenceID INT NOT NULL IDENTITY(1,1),
    ConferenceName VARCHAR(100) NOT NULL,
    constraint PK_Conference Primary Key (ConferenceID),
    constraint UQ_ConferenceName UNIQUE (ConferenceName)
);

go

create table TEAM (
    TeamID INT NOT NULL IDENTITY(1,1),
    UniversityName VARCHAR(50) NOT NULL,
    TeamName VARCHAR(100) NOT NULL,
    StadiumID INT NOT NULL,
    ConferenceID INT NULL,                              
    constraint PK_Team Primary Key (TeamID),
    constraint UQ_UniversityName UNIQUE (UniversityName),
    constraint UQ_Team_Stadium UNIQUE (StadiumID),      
    constraint FK_Team_Stadium FOREIGN KEY (StadiumID) REFERENCES STADIUM(StadiumID),
    constraint FK_Team_Conference FOREIGN KEY (ConferenceID) REFERENCES CONFERENCE(ConferenceID)
);

go

create table GAME (
    GameID INT NOT NULL IDENTITY(1,1),
    GameDate DATE NOT NULL,
    GameTime TIME NOT NULL,
    HomeScore INT NULL,
    AwayScore INT NULL,
    HomeTeamID INT NOT NULL,                          
    AwayTeamID INT NOT NULL,                           
    WinnerTeamID INT NULL,                             
    StadiumID INT NOT NULL,                             
    constraint PK_Game Primary Key (GameID),
    constraint UQ_Game UNIQUE (HomeTeamID, GameDate, GameTime),
    constraint FK_Game_HomeTeam FOREIGN KEY (HomeTeamID) REFERENCES TEAM(TeamID),
    constraint FK_Game_AwayTeam FOREIGN KEY (AwayTeamID) REFERENCES TEAM(TeamID),
    constraint FK_Game_WinnerTeam FOREIGN KEY (WinnerTeamID) REFERENCES TEAM(TeamID),
    constraint FK_Game_Stadium FOREIGN KEY (StadiumID) REFERENCES STADIUM(StadiumID),
    constraint CK_Game_Teams CHECK (HomeTeamID <> AwayTeamID),                    
    constraint CK_Game_Winner CHECK (WinnerTeamID IN (HomeTeamID, AwayTeamID))    
);

go


create table APPUSER (
    AppUserID INT NOT NULL IDENTITY(1,1),
    AppUserFirstName VARCHAR(50) NOT NULL,
    AppUserLastName VARCHAR(50) NOT NULL,
    AppUserEmail VARCHAR(100) NOT NULL,
    AppUserPassword VARCHAR(100) NOT NULL,
    AppUserRole VARCHAR(20) NOT NULL
        constraint DF_AppUser_Role DEFAULT 'User',
    constraint PK_AppUser Primary Key (AppUserID),
    constraint UQ_AppUser_Email UNIQUE (AppUserEmail),
    constraint CK_AppUser_Role CHECK (AppUserRole IN ('User', 'Admin'))
);

go


create table APPUSERTEAM (
    AppUserID INT NOT NULL,
    TeamID INT NOT NULL,
    constraint PK_AppUserTeam Primary Key (AppUserID, TeamID),
    constraint FK_AppUserTeam_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID),
    constraint FK_AppUserTeam_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID)
);

go

create table GAMEPREDICTION (
    GamePredictionID INT NOT NULL IDENTITY(1,1),
    AppUserID INT NOT NULL,
    GameID INT NOT NULL,
    PredictedWinnerTeamID INT NOT NULL,                
    PredictedMargin INT NOT NULL,                       
    PredictionDateTime DATETIME2 NOT NULL
        constraint DF_GamePrediction_DateTime DEFAULT SYSDATETIME(),
    constraint PK_GamePrediction Primary Key (GamePredictionID),
    constraint UQ_GamePrediction_UserGame UNIQUE (AppUserID, GameID),
    constraint FK_GamePrediction_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID),
    constraint FK_GamePrediction_Game FOREIGN KEY (GameID) REFERENCES GAME(GameID),
    constraint FK_GamePrediction_Team FOREIGN KEY (PredictedWinnerTeamID) REFERENCES TEAM(TeamID),
    constraint CK_GamePrediction_Margin CHECK (PredictedMargin > 0)
);

go

create table WEEKLYPREDICTIONRESULTS (
    WPRID INT NOT NULL IDENTITY(1,1),
    AppUserID INT NOT NULL,
    StartDate DATE NOT NULL,
    NumberOfCorrectPredictions INT NOT NULL
        constraint DF_WPR_Correct DEFAULT 0,
    TotalDifferenceFromPredictedMargins INT NOT NULL 
        constraint DF_WPR_MarginDiff DEFAULT 0,
    constraint PK_WPR Primary Key (WPRID),
    constraint UQ_WPR_UserWeek UNIQUE (AppUserID, StartDate),
    constraint FK_WPR_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID),
    constraint CK_WPR_NonNegative CHECK (NumberOfCorrectPredictions >= 0 AND TotalDifferenceFromPredictedMargins >= 0)
);

go


create table ROSTER (
    RosterID INT NOT NULL IDENTITY(1,1),
    Year INT NOT NULL,
    SeasonWins INT NOT NULL,
    SeasonLosses INT NOT NULL,
    SeasonTies INT NOT NULL,
    TeamID INT NOT NULL,                               
    constraint PK_Roster Primary Key (RosterID),
    constraint UQ_Roster_TeamYear UNIQUE (TeamID, Year),  
    constraint FK_Roster_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID)
);

go

create table COACH (
    CoachID INT NOT NULL IDENTITY(1,1),
    CoachName VARCHAR(100) NOT NULL,
    constraint PK_Coach Primary Key (CoachID)
);

go

create table COACHROSTER (
    CoachID INT NOT NULL,
    RosterID INT NOT NULL,
    constraint PK_CoachRoster Primary Key (CoachID, RosterID),
    constraint FK_CoachRoster_Coach FOREIGN KEY (CoachID) REFERENCES COACH(CoachID),
    constraint FK_CoachRoster_Roster FOREIGN KEY (RosterID) REFERENCES ROSTER(RosterID)
);

go


create table PLAYER (
    PlayerID INT NOT NULL IDENTITY(1,1),
    PlayerName VARCHAR(100) NOT NULL,
    PlayerDOB DATE NOT NULL,
    constraint PK_Player Primary Key (PlayerID),
    constraint UQ_PlayerName_DOB UNIQUE (PlayerName, PlayerDOB)
);

go

create table POSITION (
    PositionID INT NOT NULL IDENTITY(1,1),
    PositionName VARCHAR(50) NOT NULL,
    constraint PK_Position Primary Key (PositionID),
    constraint UQ_Position_Name UNIQUE (PositionName),
    constraint CK_Position_Name CHECK (PositionName IN ('QB', 'RB', 'Defender', 'Returner', 'Kicker', 'Punter'))
);

go

create table PLAYERPOSITION (
    PlayerID INT NOT NULL,
    PositionID INT NOT NULL,
    constraint PK_PlayerPosition Primary Key (PlayerID, PositionID),
    constraint FK_PlayerPosition_Player FOREIGN KEY (PlayerID) REFERENCES PLAYER(PlayerID),
    constraint FK_PlayerPosition_Position FOREIGN KEY (PositionID) REFERENCES POSITION(PositionID)
);

go


create table PLAYERSTATS (
    PlayerStatsID INT NOT NULL IDENTITY(1,1),
    PlayerID INT NOT NULL,
    RosterID INT NOT NULL,
    PositionID INT NOT NULL,
    constraint PK_PlayerStats Primary Key (PlayerStatsID),
    constraint UQ_PlayerStats UNIQUE (PlayerID, RosterID, PositionID),
    constraint FK_PlayerStats_Player FOREIGN KEY (PlayerID) REFERENCES PLAYER(PlayerID),
    constraint FK_PlayerStats_Roster FOREIGN KEY (RosterID) REFERENCES ROSTER(RosterID),
    constraint FK_PlayerStats_Position FOREIGN KEY (PositionID) REFERENCES POSITION(PositionID)
);

go


create table QBSTATS (
    QBStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    Attempts INT NOT NULL,
    Completions INT NOT NULL,
    Yards INT NOT NULL,
    TDs INT NOT NULL,
    INTs INT NOT NULL,
    constraint PK_QBStats Primary Key (QBStatsID),
    constraint UQ_QBStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_QBStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID),
    constraint CK_QBStats_Completions CHECK (Completions <= Attempts)
);

go

create table RBSTATS (
    RBStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    Carries INT NOT NULL,
    Yards INT NOT NULL,
    TDs INT NOT NULL,
    Long INT NOT NULL,                                 
    Fumbles INT NOT NULL,
    constraint PK_RBStats Primary Key (RBStatsID),
    constraint UQ_RBStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_RBStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID)
);

go

create table DEFENDERSTATS (
    DefenderStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    Tackles INT NOT NULL,
    Sacks DECIMAL(4,1) NOT NULL,                        
    Interceptions INT NOT NULL,
    DefensiveTDs INT NOT NULL,
    constraint PK_DefenderStats Primary Key (DefenderStatsID),
    constraint UQ_DefenderStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_DefenderStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID)
);

go

create table RETURNERSTATS (
    ReturnerStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    KickOffAttempts INT NOT NULL,
    KickOffYards INT NOT NULL,
    KickOffLong INT NOT NULL,
    KickOffTDs INT NOT NULL,
    PuntReturnAttempts INT NOT NULL,
    PuntReturnYards INT NOT NULL,
    PuntReturnLong INT NOT NULL,
    PuntReturnTDs INT NOT NULL,
    constraint PK_ReturnerStats Primary Key (ReturnerStatsID),
    constraint UQ_ReturnerStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_ReturnerStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID)
);

go

create table KICKERSTATS (
    KickerStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    FieldGoalAttempts INT NOT NULL,
    FieldGoalsMade INT NOT NULL,
    Long INT NOT NULL,                                 
    ExtraPointAttempts INT NOT NULL,
    ExtraPointsMade INT NOT NULL,
    constraint PK_KickerStats Primary Key (KickerStatsID),
    constraint UQ_KickerStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_KickerStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID),
    constraint CK_KickerStats_FG CHECK (FieldGoalsMade <= FieldGoalAttempts),
    constraint CK_KickerStats_XP CHECK (ExtraPointsMade <= ExtraPointAttempts)
);

go

create table PUNTERSTATS (
    PunterStatsID INT NOT NULL IDENTITY(1,1),
    PlayerStatsID INT NOT NULL,
    Punts INT NOT NULL,
    Yards INT NOT NULL,
    Long INT NOT NULL,                                
    constraint PK_PunterStats Primary Key (PunterStatsID),
    constraint UQ_PunterStats_PlayerStats UNIQUE (PlayerStatsID),
    constraint FK_PunterStats_PlayerStats FOREIGN KEY (PlayerStatsID) REFERENCES PLAYERSTATS(PlayerStatsID)
);

go

