
class SessionPersistence 

  def initialize(session)
    @session = session
    @session[:players] ||= []
    @session[:next_id] ||= 0
  end

  def next_player_id
    next_id = @session[:next_id] + 1
    @session[:next_id] = next_id
    next_id
  end

  def return_scores_hdcp(player_id)
    player = load_player(player_id)
    [player[:scores], player[:hdcp].to_i]
  end

  def all_players
    @session[:players]
  end

  def load_player(player_id)
    @session[:players].find { |player| player[:id] == player_id }
  end

  def scores_in_order(players_array, format)
    totals_array = []
    players_array.each do |player|
      hdcp = player[:hdcp].to_i
      gross = player[:scores].values.map {|val| val.to_i}.sum
      totals_array << { id: player[:id], name: player[:name], gross: gross, net: gross - hdcp }
    end
    return totals_array.sort_by { |hash| hash[:gross] } if format == 'gross'
    totals_array.sort_by { |hash| hash[:net] }
  end

  def add_scores(scores_hash, player_id)
    player = load_player(player_id)
    player[:scores] = scores_hash
  end

end