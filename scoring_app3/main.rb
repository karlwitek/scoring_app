require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @storage = DatabasePersistence.new
end

helpers do
  def total_score(id)
    player = @storage.load_player(id)
    hdcp = player[:hdcp]
    gross = @storage.total_gross_score_for_player(id)

    if gross > 0
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
  @payballs = @storage.format_payballs
  erb :results
end

get "/clear_scores" do
  @storage.clear_scores
  redirect "/"
end

get "/clear_players" do
  @storage.clear_players
  redirect "/"
end

post "/new_player_info" do
  name = params[:player_name].strip
  age = params[:player_age]
  hdcp = params[:handicap]
  @storage.enter_new_player(name, age, hdcp)
  redirect "/add_player"
end

post "/score_player/:player_id" do
  player_id = params[:player_id].to_i
  scores_hash = create_scores_hash(params)
  @storage.record_scores(scores_hash, player_id)
  redirect "/totals"
end
