require "sinatra"
require "sinatra/reloader"
require "haml"
require "json"
require "sass"

get '/' do
  haml :index
end

get '/laws' do
  laws = JSON.parse(File.read("./lib/laws.json"))
  @q = params[:q]
  @c = params[:c]
  if @q==nil
    @laws = laws
  else
    query = @q.split("　")
    @laws = []
    flag = @c=="a" ? true : false
    laws.each do |l|
      query.each do |q|
        flag = l["title"].include?(q)
        flag = !flag if @c=="o"
        break if !flag
      end
      if flag&&@c=="a" || !flag&&@c=="o"
        @laws.push(l)
      end
    end
  end
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


