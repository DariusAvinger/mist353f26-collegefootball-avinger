









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

