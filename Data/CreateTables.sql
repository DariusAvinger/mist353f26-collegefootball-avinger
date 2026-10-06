









if object_id('STADIUM') is not null
    drop table STADIUM;
if object_id('TEAM') is not null
    drop table TEAM;
if object_id('GAME') is not null
    drop table GAME;

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

CREATE table WEEKLYPREDICTIONRESULTS (
    PredictionID INT NOT NULL IDENTITY(1,1),
    WPRID INT NOT NULL,
    StartDate DATE NOT NULL,
    NumberOfCorrectPredictions INT NOT NULL,
    constraint PK_Prediction Primary Key (PredictionID),
    constraint FK_Prediction_Game FOREIGN KEY (GameID) REFERENCES GAME(GameID),

);

go 

CREATE table APPUSER (
    AppUserID INT NOT NULL IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL,
    Password VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    WPRID INT NULL,
    constraint PK_APPUSER Primary Key (AppUserID),
    constraint UQ_Email UNIQUE (Email),
    constraint FK_APPUSER_WPR FOREIGN KEY (WPRID) REFERENCES WEEKLYPREDICTIONRESULTS(WPRID)
);

go 

CREATE TABLE APPTEA (
    TeamID INT NOT NULL,
    AppUserID INT NOT NULL,
    constraint PK_AppTeam Primary Key (TeamID, AppUserID),
    constraint FK_AppTeam_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID),
    constraint FK_AppTeam_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID)
);

go

CREATE TABLE APPGAM (
    GameID INT NOT NULL,
    AppUserID INT NOT NULL,
    constraint PK_AppGame Primary Key (GameID, AppUserID),
    constraint FK_AppGame_Game FOREIGN KEY (GameID) REFERENCES GAME(GameID),
    constraint FK_AppGame_AppUser FOREIGN KEY (AppUserID) REFERENCES APPUSER(AppUserID)
);

go

CREATE table GAMEPREDICTION (
    PredictionID INT NOT NULL IDENTITY(1,1),
    GameID INT NOT NULL,
    TeamID INT NOT NULL,
    constraint PK_GamePrediction Primary Key (PredictionID),
    constraint FK_GamePrediction_Game FOREIGN KEY (GameID) REFERENCES GAME(GameID),
    constraint FK_GamePrediction_Winner FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID)
);

go

CREATE TABLE ROSTER (
    RosterID INT NOT NULL IDENTITY(1,1),
    Year INT NOT NULL,
    SeasonWins INT NOT NULL,
    SeasonLosses INT NOT NULL,
    SeasonTies INT NOT NULL,
    TeamID INT NOT NULL,
    constraint PK_Roster Primary Key (RosterID),
    constraint FK_Roster_Team FOREIGN KEY (TeamID) REFERENCES TEAM(TeamID)
);

go

CREATE TABLE PLAYER (
    PlayerID INT NOT NULL IDENTITY(1,1),
    PlayerName VARCHAR(100) NOT NULL,
    PlayerDOB DATE NOT NULL,
    constraint PK_Player Primary Key (PlayerID),

);

go

CREATE TABLE POSITION (
    PositionID INT NOT NULL IDENTITY(1,1),
    PositionName VARCHAR(50) NOT NULL,
    constraint PK_Position Primary Key (PositionID)
);

go  

CREATE TABLE PLAPOS (
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

CREATE TABLE COAROS (
    CoachID INT NOT NULL,
    RosterID INT NOT NULL,
    constraint PK_CoachRoster Primary Key (CoachID, RosterID),
    constraint FK_CoachRoster_Coach FOREIGN KEY (CoachID) REFERENCES COACH(CoachID),
    constraint FK_CoachRoster_Roster FOREIGN KEY (RosterID) REFERENCES ROSTER(RosterID)
);
