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

get("/search_results") do
 @artist = params.fetch("artist").gsub(" ", "+")
 @song_name = params.fetch("song_name").gsub(" ", "+")


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
