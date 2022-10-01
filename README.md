# Soccer-Leagues-DB

## Overview
![alt flow](https://github.com/Raatid-Dilly/Soccer-Leagues-DB/blob/main/images/flow.jpg)

[API-Football](https://rapidapi.com/api-sports/api/api-football/) was used to get soccer data including player and team statistics to build a PostgreSQL Database with various soccer leagues for the 2019, 2020, and 2021 seasons.  The database contains tables for leagues, teams, players, standings, team statistics, player statistics, and topscorers. As there are a large number of columns for several tables, ```pandas.DataFrame.to_sql()``` was prefered opposed to manually inserting values into the database. Due to this the datatypes of the values inserted were often wrong and would require correction. After all the tables are loaded into the database, they are then inserted into another schema.table with the correct datatypes and with primary/foreign key values. Lastly, Metabase was used to create a local dashboard for visual analysis.


### Leagues
* Brazil - Serie A
* England - Premier League
* France - Ligue 1
* Germany -  Bundesliga
* Italy - Serie A
* Mexico - Liga MX
* Netherlands - Eredivisie
* Spain - La Liga
* Portugal - Primeira Liga
* USA - Major League Soccer (MLS)


## Setup
Everything is ran in a Docker container. The **[docker-compose.yaml](https://github.com/Raatid-Dilly/Soccer-Leagues-DB/blob/main/docker-compose.yaml)** configuration is below. Note the environment variables i.e. POSTGRES_USER and POSTGRES_PASSWORD are all saved in a separate .env file.  The docker-compose file contains the following images:
* ```pgdatabase``` -  Postgres Image
* ```pgadmin``` - Used for local testing and can be viewed on localhost:8080 in a browser
* ```pythonapp``` - script to run in the Docker container 
* ```metabase``` - Metabase localhost:3000 in a browser

```
File  43 lines (42 sloc)  1.09 KB

version: '3.8'

services:
  pgdatabase:
    environment:
       - POSTGRES_USER=${POSTGRES_USER}
       - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
       - POSTGRES_DB=${POSTGRES_DB}
    # volumes:
    #   - ./warehouse/soccer_postgres_data:/var/lib/postgresql/data:rw
    ports:
      - "5432:5432"
    restart: always
    image: postgres:13
  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=${PGADMIN_EMAIL}
      - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_PASSWORD}
    depends_on: 
      - pgdatabase
    ports:
      - "8080:80"
  pythonapp:
    build: ./
    command: sh -c "sleep 20s && cd code/soccer && python soccer_leagues.py --year 2019"
    environment:
      - PG_USER=${POSTGRES_USER}
      - PG_PASSWORD=${POSTGRES_PASSWORD}
      - PG_DB=${POSTGRES_DB}
      - PG_HOST=${POSTGRES_HOST}
      - PG_PORT=${POSTGRES_PORT}
    depends_on:
      - pgdatabase
  dashboard:
    image: metabase/metabase
    container_name: dashboard
    ports:
      - "3000:3000"
    volumes:
      - ./metabase-data:/metabase-data
    environment:
      - MB_DB_FILE=/metabase-data/metabase.db
```

## Dashboard
Because metabase was ran locally the dashboard can't be shared, but below are images

![alt first](https://github.com/Raatid-Dilly/Soccer-Leagues-DB/blob/main/images/Metabase_dashboard1.png)
![alt second](https://github.com/Raatid-Dilly/Soccer-Leagues-DB/blob/main/images/Metabase_dashboard2.png)

