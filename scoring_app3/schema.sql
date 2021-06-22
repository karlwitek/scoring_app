CREATE TABLE players (
  id serial PRIMARY KEY,
  name text NOT NULL,
  age integer NOT NULL,
  hdcp integer NOT NULL
);

CREATE TABLE scores (
  hole_no integer,
  player_id integer NOT NULL REFERENCES players (id),
  score integer NOT NULL
);

CREATE TABLE course (
  hole_no serial PRIMARY KEY,
  par integer NOT NULL,
  hdcp_rating integer NOT NULL
);
