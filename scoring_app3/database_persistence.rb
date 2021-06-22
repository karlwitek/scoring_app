require "pg"

class DatabasePersistence 

  def initialize
    @db = PG.connect(dbname: "tournament")
  end

  def query(statement, *params)
    puts "#{statement} : #{params}"
    @db.exec_params(statement, params)
  end

  def all_players
    sql = "SELECT * FROM players;"
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"].to_i, name: tuple["name"], age: tuple["age"].to_i, hdcp: tuple["hdcp"].to_i }
    end
  end

  def enter_new_player(name, age, hdcp)
    sql = "INSERT INTO players (name, age, hdcp) VALUES ($1, $2, $3);"
    query(sql, name, age, hdcp)
  end

  def load_player(player_id)
    sql = "SELECT * FROM players WHERE id = $1;"
    result = query(sql, player_id)
    tuple = result.first
    { id: tuple["id"].to_i, name: tuple["name"], age: tuple["age"].to_i, hdcp: tuple["hdcp"].to_i }
  end

  def total_gross_score_for_player(player_id)
    sql = "SELECT sum(score)AS sum FROM scores WHERE player_id = $1;"
    result = query(sql, player_id)
    tuple = result.first
    tuple["sum"].to_i
  end

  def scores_in_order(players_array, format)
    totals_array = []
    players_array.each do |player|
      hdcp = player[:hdcp].to_i
      gross = total_gross_score_for_player(player[:id])
      net_score = 0
      net_score = gross - hdcp unless gross == 0

      totals_array << { id: player[:id], name: player[:name], gross: gross, net: net_score }
    end
    return totals_array.sort_by { |hash| hash[:gross] } if format == 'gross'
    totals_array.sort_by { |hash| hash[:net] }
  end

  def record_scores(scores_hash, player_id)
    array_of_scores = scores_hash.values.map { |score| score.to_i }
    sql = "INSERT INTO scores (hole_no, player_id, score) VALUES ($1, $2, $3);"
    hole_no = 1
    array_of_scores.each do |score|
      query(sql, hole_no, player_id, score)
      hole_no += 1
    end
  end

  def find_lowest_score_on_hole
    sql =<<~SQL
      SELECT hole_no, min(score) AS score
      FROM scores GROUP BY hole_no
      ORDER BY hole_no;
    SQL
    scores = {}
    result = query(sql)
    result.each do |tuple|
      scores[tuple["hole_no"]] = tuple["score"].to_i
    end
    scores
  end

  def find_payballs
    payballs = []
    scores = find_lowest_score_on_hole
    sql = "SELECT player_id, score, hole_no FROM scores WHERE hole_no = $1 AND score = $2;"
    scores.each do |hole_no, score|
      result = query(sql, hole_no, score)
      if result.ntuples == 1
        payballs << result
      end
    end
    payballs
  end

  def format_payballs
    payballs = find_payballs
    skins = []
    payballs.each do |pb|
      tuple = pb.first
      id = tuple["player_id"].to_i
      player = load_player(id)
      skins << { hole: tuple["hole_no"], name: player[:name],  score: tuple["score"] }
    end
    skins
  end

  def clear_scores
    @db.exec("DELETE FROM scores;")
  end

  def clear_players
    @db.exec("DELETE FROM scores;")
    @db.exec("DELETE FROM players;")
  end
end