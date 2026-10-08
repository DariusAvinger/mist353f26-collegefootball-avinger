







if object_id('APPUSERTEAM') is not null drop table APPUSERTEAM;
if object_id('PLAYERPOSITION') is not null drop table PLAYERPOSITION;
if object_id('COACHROSTER') is not null drop table COACHROSTER;
if object_id('PLAYERSTATS') is not null drop table PLAYERSTATS;
if object_id('GAMEPREDICTION') is not null drop table GAMEPREDICTION;
if object_id('WEEKLYPREDICTIONRESULTS') is not null drop table WEEKLYPREDICTIONRESULTS;
if object_id('APPUSER') is not null drop table APPUSER;
if object_id('COACH') is not null drop table COACH;
if object_id('POSITION') is not null drop table POSITION;
if object_id('PLAYER') is not null drop table PLAYER;
if object_id('ROSTER') is not null drop table ROSTER;
if object_id('GAME') is not null drop table GAME;
if object_id('TEAM') is not null drop table TEAM;
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

CREATE table TEAM (
    TeamID INT NOT NULL IDENTITY(1,1),
    UniversityName VARCHAR(50) NOT NULL,
    TeamName VARCHAR(100) NOT NULL,
    StadiumID INT NOT NULL,
    constraint PK_Team Primary Key (TeamID),
    constraint UQ_UniversityName UNIQUE (UniversityName)
);


go


CREATE table GAME (
    GameID INT NOT NULL IDENTITY(1,1),
    GameDate Date NOT NULL,
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
    constraint FK_Game_Stadium FOREIGN KEY (StadiumID) REFERENCES STADIUM(StadiumID)
);


go 

create table APPUSER (
    AppUserID INT NOT NULL IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    AppUserEmail VARCHAR(100) NOT NULL,
    AppUserPassword VARCHAR(100) NOT NULL,
    constraint PK_AppUser Primary Key (AppUserID),
    constraint UQ_AppUser_Email UNIQUE (AppUserEmail)
);


go 

create table APPUSERTEAM (
    TeamID INT NOT NULL,
    AppUserID INT NOT NULL,
    constraint UQ_AppUserTeam UNIQUE (AppUserID,TeamID),
    constraint PK_AppUserTeam Primary Key (AppUserID),
    constraint FK_AppUserTeam_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID),
    constraint FK_AppUserTeam_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID)
);


go

create table GAMEPREDICTION (
    GamePredictionID INT NOT NULL IDENTITY(1,1),
    AppUserID INT NOT NULL,
    GameID INT NOT NULL,
    PredictedWinnerTeamID INT NOT NULL,  
    PredictionDateTime DATETIME2 NOT NULL
        constraint DF_GamePrediction_DateTime DEFAULT SYSDATETIME(),
    constraint PK_GamePrediction Primary Key (GamePredictionID),
    constraint UQ_GamePrediction_UserGame UNIQUE (AppUserID, GameID),
    constraint FK_GamePrediction_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID),
    constraint FK_GamePrediction_Game FOREIGN KEY (GameID) REFERENCES GAME(GameID),
    constraint FK_GamePrediction_Team FOREIGN KEY (PredictedWinnerTeamID) REFERENCES TEAM(TeamID)
);

go


create table WEEKLYPREDICTIONRESULTS (
    WPRID INT NOT NULL IDENTITY(1,1),
    AppUserID INT NOT NULL,
    StartDate DATE NOT NULL,
    NumberOfCorrectPredictions INT NOT NULL
        constraint DF_WPR_Correct DEFAULT 0,
    constraint PK_WPR Primary Key (WPRID),
    constraint UQ_WPR_UserWeek UNIQUE (AppUserID, StartDate),
    constraint FK_WPR_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID)
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
    constraint UQ_Roster_TeamYear UNIQUE (TeamID, Year),  -- one roster per team per season
    constraint FK_Roster_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID)
);



go

create table PLAYER (
    PlayerID INT NOT NULL IDENTITY(1,1),
    PlayerName VARCHAR(100) NOT NULL,
    PlayerDOB DATE NOT NULL,
    constraint PK_Player Primary Key (PlayerID)
);

go

create table PLAYERROSTER (
    PlayerID INT NOT NULL,
    RosterID INT NOT NULL,
    constraint PK_PlayerRoster Primary Key (PlayerID, RosterID),
    constraint FK_PlayerRoster_Player FOREIGN KEY (PlayerID) REFERENCES PLAYER(PlayerID),
    constraint FK_PlayerRoster_Roster FOREIGN KEY (RosterID) REFERENCES ROSTER(RosterID)
);

go

create table POSITION (
    PositionID INT NOT NULL IDENTITY(1,1),
    PositionName VARCHAR(50) NOT NULL,
    constraint PK_Position Primary Key (PositionID),
    
);


go  

CREATE TABLE PLAYERPOSITION (
    PlayerID INT NOT NULL,
    PositionID INT NOT NULL,
    constraint PK_PlayerPosition Primary Key (PlayerID, PositionID),
    constraint FK_PlayerPosition_Player FOREIGN KEY (PlayerID) REFERENCES PLAYER(PlayerID),
    constraint FK_PlayerPosition_Position FOREIGN KEY (PositionID) REFERENCES POSITION(PositionID)
);

go

CREATE TABLE COACH (
    CoachID INT NOT NULL IDENTITY(1,1),
    CoachName VARCHAR(100) NOT NULL,
    constraint PK_Coach Primary Key (CoachID),

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



