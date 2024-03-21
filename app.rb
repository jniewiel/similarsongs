# app.rb

require "sinatra"
require "sinatra/reloader"
require "http"

# ---------------------------------------------------------- #

get("/") do
  redirect(:search)
end

# ---------------------------------------------------------- #

get("/search") do
  erb(:search)
end

# ---------------------------------------------------------- #


def build_api_url(method, artist, song_name)
  "https://ws.audioscrobbler.com/2.0/?method=#{method}&artist=#{artist}&track=#{song_name}&api_key=#{ENV["LASTFM_API_KEY"]}&format=json"
end

get("/search_results") do
  # test
  @artist = params.fetch("artist").gsub(" ", "%20")
  @song_name = params.fetch("song_name").gsub(" ", "%20")

  api_correct = build_api_url("track.getcorrection", @artist, @song_name)
  @raw_data_correct = HTTP.get(api_correct).to_s
  parsed_data_correct = JSON.parse(@raw_data_correct)

  # test
  if parsed_data_correct.nil? || parsed_data_correct == {} || parsed_data_correct["correction"].nil? || parsed_data_correct["correction"]["corrected"].nil?
    @results_corrected = parsed_data_correct
    erb(:test)
  # test
  
  else
    @results_corrected = parsed_data_correct["corrections"]["correction"]["track"]
    @corrected_artist = results_corrected["artist"]["name"].gsub("+", "%20")
    @corrected_song = results_corrected["name"].gsub("+", "%20")

    api_info = build_api_url("track.getinfo", @corrected_artist, @corrected_song)
    raw_data_info = HTTP.get(api_info).to_s
    parsed_data_info = JSON.parse(raw_data_info)

    if parsed_data_info["track"].nil? || parsed_data_info["track"]["wiki"].nil?
      erb(:search)
    else
      results_info = parsed_data_info["track"]
      @summary = results_info["wiki"]["summary"]
      @cover = results_info["album"] && results_info["album"]["image"][2]["#text"]

      api_search = build_api_url("track.getsimilar", @corrected_artist, @corrected_song) + "&limit=5"
      final_recommendations = []

      raw_data = HTTP.get(api_search).to_s
      parsed_data = JSON.parse(raw_data)

      if parsed_data && parsed_data["similartracks"]["track"].any?
        5.times do |index|
          results = parsed_data["similartracks"]["track"]
          @rec_artist_name = results[index]["artist"]["name"]
          @rec_song_name = results[index]["name"]
          @rec_track_link = "https://www.last.fm/music/#{@rec_artist_name}/_/#{@rec_song_name}"
    
          track = { @rec_artist_name => @rec_song_name }
          bundle = { track => @rec_track_link }
    
          final_recommendations.push(bundle)
        end
      end

      @final = final_recommendations
      erb(:search_results)
    end
  end
end



# ---------------------------------------------------------- #
# ignore previous code

=begin
get("/search_results") do
  @artist = params.fetch("artist").gsub(" ", "%20")
  @song_name = params.fetch("song_name").gsub(" ", "%20")

  @api_correct = "https://ws.audioscrobbler.com/2.0/?method=track.getcorrection&artist=#{@artist}&track=#{@song_name}&api_key=#{ENV["LASTFM_API_KEY"]}&format=json"

  raw_data_correct = HTTP.get(@api_correct).to_s
  @parsed_data_correct = JSON.parse(raw_data_correct)

  if @parsed_data_correct == nil
    erb(:search)
  elsif @parsed_data_correct == {}
    erb(:search)
  else
    results_corrected = @parsed_data_correct["corrections"]["correction"]["track"]
    @corrected_artist = results_corrected["artist"]["name"].gsub(" ", "%20")
    @corrected_song = results_corrected["name"].gsub(" ", "%20")
  end

  # -----------------------------
  @api_info = "https://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=#{@corrected_artist}&track=#{@corrected_song}&api_key=#{ENV["LASTFM_API_KEY"]}&format=json"

  raw_data_info = HTTP.get(@api_info).to_s
  @parsed_data_info = JSON.parse(raw_data_info)

  if @parsed_data_info["track"].nil?
    erb(:search)
  else
    results_info = @parsed_data_info["track"]
  end

  if results_info == nil
    erb(:search)
  elsif results_info["wiki"] == nil
    erb(:search)
  else
    @summary = results_info["wiki"]["summary"]
  end

  if results_info == nil
    erb(:search)
  elsif results_info["album"] == nil
    @cover = nil
  else
    @cover = results_info["album"]["image"][2]["#text"]
  end

  # -----------------------------
  api_search = "https://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=#{@corrected_artist}&track=#{@corrected_song}&api_key=#{ENV["LASTFM_API_KEY"]}&format=json&limit=5"

  @final = []

  raw_data = HTTP.get(api_search).to_s
  @parsed_data = JSON.parse(raw_data)

  if @parsed_data.nil? || @parsed_data == {} || @parsed_data["similartracks"]["track"] == []
    erb(:search)
  else
    results = @parsed_data["similartracks"]["track"]

    5.times do |index|
      @rec_artist_name = results[index]["artist"]["name"]
      @rec_song_name = results[index]["name"]
      @rec_track_link = "https://www.last.fm/music/#{@rec_artist_name}/_/#{@rec_song_name}"

      track = { @rec_artist_name => @rec_song_name }
      bundle = { track => @rec_track_link }

      @final.push(bundle)
    end
  end

  # -----------------------------
  erb(:search_results)
end
=end
