require "sinatra"
require "sinatra/reloader"
require "haml"
require "json"
require "sass"

get '/' do
  haml :index
end

get '/laws' do
  @laws = JSON.parse(File.read("./lib/laws.json"))
  @q = params[:q]
  haml :laws
end

get '/laws/:id' do |id|
  @art = JSON.parse(File.read("./data/#{id}.json"))
  @id = id
  haml :article
end

get '/tmp/style.css' do
  sass :style
end


