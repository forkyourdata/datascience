######## file download #########

https://dsserver-prod-resources-1.s3.amazonaws.com/376/game_log.csv
https://dsserver-prod-resources-1.s3.amazonaws.com/376/park_codes.csv
https://dsserver-prod-resources-1.s3.amazonaws.com/376/person_codes.csv
https://dsserver-prod-resources-1.s3.amazonaws.com/376/team_codes.csv


#read library
library(readr)
library(DBI)
library(RSQLite)

#gamelog <- read_csv("game_log.csv")
#964299 parsing failures.
#problems(gamelog)
#https://readr.tidyverse.org/articles/readr.html
#Overriding the defaults : readr will only print the specification of the first 20 columns.
#col_character() [c], everything else.
game_log <- read_csv("game_log.csv", col_types = cols(.default = "c",
                                                     v_league = "c", h_league = "c",
                                                    `3b_umpire_id` = "c", `3b_umpire_name` = "c",
                                                    `2b_umpire_id` = "c", `2b_umpire_name` = "c",
                                                    `lf_umpire_id` = "c", `lf_umpire_name` = "c",
                                                    `rf_umpire_id` = "c", `rf_umpire_name` = "c",
                                                    completion = "c", winning_rbi_batter_id = "c",
                                                    winning_rbi_batter_id_name = "c", protest = "c",
                                                    v_first_catcher_interference = "c", 
                                                    h_first_catcher_interference = "c"), guess_max = 1e6)
team_codes <- read_csv("team_codes.csv")
park_codes <- read_csv("park_codes.csv")
person_codes <- read_csv("person_codes.csv")
# iporting data
conn <- dbConnect(SQLite(), "mlb.db")
dbWriteTable(conn = conn, name = "game_log", value = game_log, row.names = FALSE, header = TRUE)
dbWriteTable(conn = conn, name = "team_codes", value = team_codes, row.names = FALSE, header = TRUE)
dbWriteTable(conn = conn, name = "park_codes", value = park_codes, row.names = FALSE, header = TRUE)
dbWriteTable(conn = conn, name = "person_codes", value = person_codes, row.names = FALSE, header = TRUE)

dbListTables(conn)

dbExecute(conn, "ALTER TABLE game_log
                 ADD COLUMN game_id TEXT;")
dbExecute(conn, "UPDATE game_log
                 SET game_id = date || h_name || number_of_game
                 WHERE game_id IS NULL;")

str(game_log)




dbExecute(conn, "CREATE TABLE person(
                    person_id TEXT PRIMARY KEY,
                    last_name TEXT,
                    first_name TEXT);")

dbExecute(conn, "INSERT INTO person
                 SELECT 
                        id, 
                        last, 
                        first 
                 FROM person_codes;")

dbGetQuery(conn, "SELECT * FROM person LIMIT 10;")



dbExecute(conn, "CREATE TABLE park (
                    park_id TEXT PRIMARY KEY,
                    name TEXT,
                    nickname TEXT,
                    city TEXT,
                    state TEXT,
                    notes TEXT);")

dbExecute(conn, "INSERT INTO park
                 SELECT 
                        park_id,
                        name,
                        aka,
                        city,
                        state,
                        notes
                 FROM park_codes;
                ")

dbGetQuery(conn, "SELECT * FROM park LIMIT 10;")



dbExecute(conn, "CREATE TABLE league (
                    league_id TEXT PRIMARY KEY,
                    name TEXT);")

dbExecute(conn, "INSERT INTO league
                 VALUES
                       ('NL', 'National League'),
                       ('AL', 'American League'),
                       ('FL', 'Federal League'),
                       ('PL', 'Players League'),
                       ('AA', 'American Association'),
                       ('UA', 'Union Association');")

dbGetQuery(conn, "SELECT * FROM league LIMIT 10;")


appearance_type <- read_csv("appearance_type.csv")

dbWriteTable(conn = conn, name = "appearance_type", value = appearance_type, row.names = FALSE, header = TRUE)

dbGetQuery(conn, "SELECT * FROM appearance_type LIMIT 10;")


dbExecute(conn, "CREATE TABLE team (
                    team_id TEXT PRIMARY KEY,
                    league_id TEXT,
                    city TEXT,
                    nickname TEXT,
                    franch_id TEXT,
                    FOREIGN KEY (league_id) REFERENCES league(league_id));")

dbExecute(conn, "INSERT OR IGNORE INTO team
                 SELECT 
                       team_id,
                       league,
                       city,
                       nickname,
                       franch_id
                 FROM team_codes;")

dbGetQuery(conn, "SELECT * FROM team LIMIT 10;")



dbExecute(conn, "CREATE TABLE game (
                    game_id TEXT PRIMARY KEY,
                    date TEXT,
                    number_of_game INTEGER,
                    park_id TEXT,
                    length_out INTEGER,
                    day BOOLEAN,
                    completion TEXT,
                    forefeit TEXT,
                    protest TEXT,
                    attendance INTEGER,
                    length_minutes INTEGER,
                    aditional_info TEXT,
                    acquisition_info TEXT,
                    FOREIGN KEY(park_id) REFERENCES park(park_id));"
          )

dbExecute(conn, "INSERT INTO game
                 SELECT
                       game_id,
                       date,
                       number_of_game,
                       park_id,
                       length_outs,
                       CASE 
                           WHEN day_night = 'D' THEN 1
                           WHEN day_night = 'N' THEN 0
                           ELSE NULL
                           END
                           AS day,
                       completion,
                       forefeit,
                       protest,
                       attendance,
                       length_minutes,
                       additional_info,
                       acquisition_info
                  FROM game_log;")

dbGetQuery(conn, "SELECT * FROM game LIMIT 10;")



dbExecute(conn, "CREATE TABLE team_appearance (
                    team_id TEXT,
                    game_id TEXT,
                    home BOOLEAN,
                    league_id TEXT,
                    score INTEGER,
                    line_score TEXT,
                    at_bats INTEGER,
                    hits INTEGER,
                    doubles INTEGER,
                    triples INTEGER,
                    homeruns INTEGER,
                    rbi INTEGER,
                    sacrifice_hits INTEGER,
                    sacrifice_flies INTEGER,
                    hit_by_pitch INTEGER,
                    walks INTEGER,
                    intentional_walks INTEGER,
                    strikeouts INTEGER,
                    stolen_bases INTEGER,
                    caught_stealing INTEGER,
                    grounded_into_double INTEGER,
                    first_catcher_interference INTEGER,
                    left_on_base INTEGER,
                    pitchers_used INTEGER,
                    individual_earned_runs INTEGER,
                    team_earned_runs INTEGER,
                    wild_pitches INTEGER,
                    balks INTEGER,
                    putouts INTEGER,
                    assists INTEGER,
                    errors INTEGER,
                    passed_balls INTEGER,
                    double_plays INTEGER,
                    triple_plays INTEGER,
                    PRIMARY KEY (team_id, game_id),
                    FOREIGN KEY (team_id) REFERENCES team(team_id),
                    FOREIGN KEY (game_id) REFERENCES game(game_id),
                    FOREIGN KEY (league_id) REFERENCES league(league_id));")

dbExecute(conn, "INSERT INTO team_appearance
                 SELECT
                       h_name,
                       game_id,
                       1 AS home,
                       h_league,
                       h_score,
                       h_line_score,
                       h_at_bats,
                       h_hits,
                       h_doubles,
                       h_triples,
                       h_homeruns,
                       h_rbi,
                       h_sacrifice_hits,
                       h_sacrifice_flies,
                       h_hit_by_pitch,
                       h_walks,
                       h_intentional_walks,
                       h_strikeouts,
                       h_stolen_bases,
                       h_caught_stealing,
                       h_grounded_into_double,
                       h_first_catcher_interference,
                       h_left_on_base,
                       h_pitchers_used,
                       h_individual_earned_runs,
                       h_team_earned_runs,
                       h_wild_pitches,
                       h_balks,
                       h_putouts,
                       h_assists,
                       h_errors,
                       h_passed_balls,
                       h_double_plays,
                       h_triple_plays
                FROM game_log
                
                UNION
                
                SELECT    
                      v_name,
                      game_id,
                      0 AS home,
                      v_league,
                      v_score,
                      v_line_score,
                      v_at_bats,
                      v_hits,
                      v_doubles,
                      v_triples,
                      v_homeruns,
                      v_rbi,
                      v_sacrifice_hits,
                      v_sacrifice_flies,
                      v_hit_by_pitch,
                      v_walks,
                      v_intentional_walks,
                      v_strikeouts,
                      v_stolen_bases,
                      v_caught_stealing,
                      v_grounded_into_double,
                      v_first_catcher_interference,
                      v_left_on_base,
                      v_pitchers_used,
                      v_individual_earned_runs,
                      v_team_earned_runs,
                      v_wild_pitches,
                      v_balks,
                      v_putouts,
                      v_assists,
                      v_errors,
                      v_passed_balls,
                      v_double_plays,
                      v_triple_plays
                      from game_log;
        ")

dbGetQuery(conn, "SELECT * FROM team_appearance WHERE score = 3 LIMIT 5;")

dbExecute(conn, "CREATE TABLE person_appearance (
                    appearance_id INTEGER PRIMARY KEY,
                    person_id TEXT,
                    team_id TEXT,
                    game_id TEXT,
                    appearance_type_id,
                    FOREIGN KEY(person_id) REFERENCES person(person_id),
                    FOREIGN KEY(team_id) REFERENCES team(team_id),
                    FOREIGN KEY(game_id) REFERENCES game(game_id),
                    FOREIGN KEY(appearance_type_id) REFERENCES appearance_type(appearance_type_id));
                 ")
dbExecute(conn, "INSERT INTO person_appearance (
                             game_id,
                             team_id,
                             person_id,
                             appearance_type_id
                  )
                 SELECT
                       game_id,
                       NULL,
                       lf_umpire_id,
                       'ULF'
                 FROM game_log
                 WHERE lf_umpire_id IS NOT NULL
                  
                 UNION
                  
                 SELECT
                       game_id,
                       NULL,
                       rf_umpire_id,
                       'URF'
                       FROM game_log
                       WHERE rf_umpire_id IS NOT NULL
                  
                 UNION
                  
                 SELECT
                       game_id,
                       v_name,
                       v_manager_id,
                       'MM'
                 FROM game_log
                 WHERE v_manager_id IS NOT NULL
                  
                 UNION
                  
                 SELECT
                       game_id,
                       h_name,
                       h_manager_id,
                       'MM'
                 FROM game_log
                 WHERE h_manager_id IS NOT NULL
                  
                 UNION
                  
                 SELECT
                       game_id,
                       CASE
                       WHEN h_score > v_score THEN h_name
                       ELSE v_name
                       END,
                       winning_pitcher_id,
                       'AWP'
                 FROM game_log
                 WHERE winning_pitcher_id IS NOT NULL
          
                 UNION
  
                 SELECT
                       game_id,
                       CASE
                       WHEN h_score < v_score THEN h_name
                       ELSE v_name
                       END,
                       losing_pitcher_id,
                       'ALP'
                FROM game_log
                WHERE losing_pitcher_id IS NOT NULL
                
                UNION
                
                SELECT
                      game_id,
                      CASE
                      WHEN h_score > v_score THEN h_name
                      ELSE v_name
                      END,
                      saving_pitcher_id,
                      'ASP'
                FROM game_log
                WHERE saving_pitcher_id IS NOT NULL
                
                UNION
                
                SELECT
                      game_id,
                      CASE
                      WHEN h_score > v_score THEN h_name
                      ELSE v_name
                      END,
                      winning_rbi_batter_id,
                      'AWB'
                FROM game_log
                WHERE winning_rbi_batter_id IS NOT NULL
                
                UNION
                
                SELECT
                      game_id,
                      v_name,
                      v_starting_pitcher_id,
                      'PSP'
                FROM game_log
                WHERE v_starting_pitcher_id IS NOT NULL
                
                UNION
                
                SELECT
                      game_id,
                      h_name,
                      h_starting_pitcher_id,
                      'PSP'
                FROM game_log
                WHERE h_starting_pitcher_id IS NOT NULL;")

for (letter in c("h", "v")) {
  for (num in 1:9) {
    template <- '
    INSERT INTO person_appearance (
    game_id,
    team_id,
    person_id,
    appearance_type_id
    ) 
    SELECT
    game_id,
    %s_name,
    %s_player_%f_id,
    "O%f"
    FROM game_log
    WHERE %s_player_%f_id IS NOT NULL
    
    UNION
    
    SELECT
    game_id,
    %s_name,
    %s_player_%f_id,
    "D" || CAST(%s_player_%f_def_pos AS INT)
    FROM game_log
    WHERE %s_player_%f_id IS NOT NULL;
    '
# replace all of the %s and %f with the correct letter number
    template <- gsub("%s", letter, template, fixed = TRUE)
    template <- gsub("%f", num, template, fixed = TRUE)

    dbExecute(conn, template)
  }
}


tables <- c("game_log", "park_codes",
            "team_codes", "person_codes")

for (t in tables) {
    dbExecute(conn, sprintf("DROP TABLE %s", t))
}
dbListTables(conn)
dbDisconnect(conn)
