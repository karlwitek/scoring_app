require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative "session_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @storage = SessionPersistence.new(session)
end

helpers do
  def total_score(id)
    scores, hdcp = @storage.return_scores_hdcp(id)

    if scores
      gross = scores.values.map {|val| val.to_i}.sum
      "Score:  Gross: #{gross} /  Net: #{gross - hdcp}"
    else
      "Player not finished"
    end
  end
end

def create_scores_hash(params)
  params.select { |key, _v| /h\w+/.match(key) }
end

get "/" do 
  erb :welcome_page
end

get "/add_player" do
  erb :new_player
end

get "/display_players" do
  @players = @storage.all_players
  erb :player_list
end

get "/score_player/:player_id" do
  player_id = params[:player_id].to_i
  @player = @storage.load_player(player_id)
  erb :score_entry
end

get "/totals" do
  @players = @storage.all_players
  erb :totals
end

get "/results" do
  @gross_scores = @storage.scores_in_order("gross")
  @net_scores = @storage.scores_in_order("net")
  erb :results
end

post "/new_player_info" do
  name = params[:player_name].strip
  age = params[:player_age]
  id = @storage.next_player_id
  hdcp = params[:handicap]
  @storage.all_players << { id: id, name: name, age: age, hdcp: hdcp }
  redirect "/add_player"
end

post "/score_player/:player_id" do
  player_id = params[:player_id].to_i
  scores_hash = create_scores_hash(params)
  @storage.add_scores(scores_hash, player_id)
  redirect "/totals"
end
