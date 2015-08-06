require "sinatra"
require "sinatra/reloader"
require "haml"
require "json"
require "sass"
require "mecab"
require "matrix"

get '/' do
  haml :index
end

get '/laws' do
  @laws = JSON.parse(File.read("./lib/laws.json"))
  @group = JSON.parse(File.read("./lib/group.json"))
  @type = JSON.parse(File.read("./lib/type.json"))
  haml :laws
end

post '/laws' do
  @laws = JSON.parse(File.read("./lib/laws.json"))
  @group = JSON.parse(File.read("./lib/group.json"))
  @type = JSON.parse(File.read("./lib/type.json"))
  @q = params[:q]
  @q_c = params[:q_c] # aならAND、oならOR検索
  @q_exam = params[:q_exam]
  # 選択されたものが配列になっている
  @q_group = params[:q_group]
  @q_type = params[:q_type]
  # 年号指定
  @q_first = params[:q_first].to_i
  @q_last = params[:q_last].to_i

  # 検索ワードに引っかかるか
  if @q!=nil
    query = @q.split("　")
    flag = @q_c=="a" ? true : false
    @laws.map! do |l|
      query.each do |q|
        flag = l["title"].include?(q)
        flag = !flag if @q_c=="o"
        break if !flag
      end
      l if flag&&@q_c=="a" || !flag&&@q_c=="o"
    end
    @laws.compact!
  end

  # 司法試験科目の抽出
  if @q_exam != nil
    bar_exam = ["S21KE000", "M29HO089", "H18HO048", "M32HO048", 
                "H17HO086", "H08HO109", "M40HO045", "S23HO131", 
                "S22HO125", "S37HO160", "S37HO139"]
    @laws.map!{|l| l if bar_exam.include?(l["id"])  }
    @laws.compact!
  end

  # ジャンルの抽出
  if @q_group!=nil && @q_group.length<50
    @laws.map! do |l|
      l if @q_group.include?(l["group"].split("_")[2])
    end
    @laws.compact!
  end

  # タイプの抽出
  if @q_type!=nil && @q_type.length<5
    @laws.map! do |l|
      l if @q_type.include?(l["id"].match(/[A-Z]+\d+([A-Z]+)\d+/)[1])
    end
    @laws.compact!
  end

  # 年号の指定
  if @q_first>0
    @laws.map! do |l|
      l if @q_first <= l["id"].match(/([A-Z]+\d+)[A-Z]+\d+/)[1].era2anno
    end
    @laws.compact!
  end
  if @q_last>0
    @laws.map! do |l|
      l if @q_last >= l["id"].match(/([A-Z]+\d+)[A-Z]+\d+/)[1].era2anno
    end
    @laws.compact!
  end

  haml :laws
end

get '/laws/:id' do |id|
  @art = JSON.parse(File.read("./data/#{id}.json"))
  @id = id
  haml :article
end

get '/laws/:id/:num' do |id, num|
  @art = JSON.parse(File.read("./data/#{id}.json"))
  @id = id
  @num = num
  @s = Similarity.new
  @this_art = @art["body"][@num]["main"]

  # 条文をcos類似度の高い順に並べ替える
  @output = @art["body"].sort_by do |n, m|
    - @s.sim(@this_art, m["main"])
  end

  haml :similarity
end

get '/tmp/style.css' do
  sass :style
end

class String
  def era2anno
    n = self[1..2].to_i
    case self[0]
      when "M" then 1966+n
      when "T" then 1911+n
      when "S" then 1925+n
      when "H" then 1988+n
    end
  end
end
class Similarity
  def sim(str1,str2)
    vec = []; vec1 = []; vec2 = []
    arr1 = []; arr2 = []

    node1 = MeCab::Tagger.new.parseToNode(str1)
    node2 = MeCab::Tagger.new.parseToNode(str2)

    vec1.push(node1.surface) if /^名詞/ =~ node1.feature while node1 = node1.next
    vec2.push(node2.surface) if /^名詞/ =~ node2.feature while node2 = node2.next
    vec1.delete("")
    vec2.delete("")

    vec.concat(vec1).concat(vec2).uniq!

    vec.each do |word|
      count = 0
      vec1.each {|w| count+=1 if word==w}
      arr1.push(count)
      count = 0
      vec2.each {|w| count+=1 if word==w}
      arr2.push(count)
    end

    v1 = Vector.elements(arr1)
    v2 = Vector.elements(arr2)

    v1.inner_product(v2)/(v1.norm * v2.norm)
  end
end


