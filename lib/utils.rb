require "utils/version"
require 'open-uri'
require 'fileutils'
require 'fastimage'
require "io/console"
require 'gtk2'

module Utils
  #Pythonの配列のsliceと同等のメソッド
  #stepは省略可。leftとrightは省略する代わりにnil
  module Pyrb
    def pickup(left, right, step=nil)
      klass = self.class
      len = self.length
      unless step
        return klass.new unless !right or right != 0
        left ||= 0
        right ||= 0
        right -= 1
        self[left..right]
            else
        if step > 0
          left ||= 0
          right ||= len
          left = convp(left, len)
          right = convp(right, len)
          right = len if right >= len
          right -= 1
        elsif step < 0
          left ||= len - 1
          left = len - 1 if left >= len
          right ||= - len - 1
          left = convm(left, len)
          right = convm(right, len)
          right = - len - 1 if right < - len - 1
          right += 1
        else
          raise "ValueError: slice step cannot be zero"
        end
        selected = klass.new
        left.step(right, step) {|i| selected << self[i]}
        selected
      end
    end
    
    def convp(i, len)
      return i if i >= 0
      i + len
    end
    
    def convm(i, len)
      return i if i < 0
      i - len
    end
    private :convp, :convm
  end
  Array.send(:include, Pyrb)
  String.send(:include, Pyrb)  
  
  def imgexist?(url)
    FastImage.size(url)
  end
  
  def getfile(url, filename, max=0)
    count = 0
    begin
      open(filename, 'wb') do |file|
        open(url) {|data| file.write(data.read)}
      end
      true 
    rescue
      puts "ファイル入出力エラー： " + $!.message.encode("UTF-8")
      count += 1
      return false if count > max  #max回までリトライする
      puts "リトライ： #{count}"
      sleep(1)
      retry
    end
  end
  module_function :imgexist?, :getfile
end
  
class String 
  def imgsuffix
    [".jpg", ".gif", ".png", ".jpeg", ".bmp", ".JPG", ".GIF", ".PNG", ".JPEG", ".BMP"].each do |sf|
      return sf if include?(sf)
    end
    ""
  end
  
  #文字列をあらゆる n 通リに分割する（ブロックがあれば実行、なければEnumeratorを返す）
  def separate(n)
    ar = seprt2(n)
    if block_given?
      ar.each {|ob| yield(ob)}
    else
      ar.to_enum
    end
  end
  
  def seprt2(n)
    return [[self]] if n <= 1 or n > self.length
    if n == 2
      st = self
      return [[st]] if st.length == 1
      ar = []
      (st.length - 1).times {|i| ar << [st[0..i], st[i + 1..-1]]}
      ar
    else
      seprt([[self]], n)
    end
  end
  
  def seprt(ar, n)
    if n == 2
      a = []
      ar.each do |ar1|
        b = ar1.dup
        ar1.each_with_index do |st, j|
          next if st.length == 1
          st.separate(2).each do |ar2|
            c = b.dup
            c[j] = ar2
            c.flatten!
            a << c
          end
        end
      end
      a.uniq
    else
      (n - 1).times {ar = seprt(ar, 2)}
      ar
    end
  end
  private :seprt, :seprt2
  
  #循環小数を分数に直す
  alias :__to_r__ :to_r
  def to_r
    s = self
    sign = 1
    if s[0] == "-"
      sign = - 1
      s = s[1..-1]
    end
    m = /(\d+)\.(\d*)\((\d+)\)$/.match(s)
    unless m
      __to_r__
    else
      a = (m[1] + "." + m[2]).__to_r__
      b = ((m[1] + m[2] + m[3]).to_i * 10 ** (- m[2].length)).to_r
      (sign * (b - a) / (10 ** m[3].length - 1)).to_r
    end
  end
  protected :__to_r__
end

class Array
  #任意の階層だけ繰り返しをネストする
  def nest_loop(arg = [], &bk)
    check = lambda do |obj|
      return 0...obj if (c = obj.class) == Bignum or c == Integer or c == Fixnum
      obj
    end
    
    ar = dup
    for i in check.call(ar.shift)
      if ar.empty?
        yield(arg + [i])
      else
        ar.nest_loop(arg.push(i), &bk)
        arg.pop
      end
    end
    self
  end
end

module Kernel
  #indexつき無限ループ
  def loop_with_index(i = 0, step = 1)
    begin
      yield(i)
    end while (i += step)
  end
end

class Rational
  #分数を循環小数に直す
  def to_rec_decimal
    st = main(self.abs)
    self.no_minus? ? st : "-" + st
  end
  
  def rec_decimal?
    slf = self.abs
    @nume = slf.numerator
    @deno = slf.denominator
    return false if @deno == 1
    get_rcycle.size == 1 ? false : true
  end

  def abs
    self.no_minus? ? self : self * (-1)
  end
  
  def no_minus?
    self.numerator >= 0
  end
  
  def no_plus?
    self.numerator <= 0
  end
  
  def main(slf)
    @nume = slf.numerator
    @deno = slf.denominator
    return "#{@nume}" if @deno == 1
    n = @nume / @deno
    ar = get_rcycle
    repetition_num = {}
    s = {}
    return "#{n}.#{ar[0][1..-1].join}" if ar.size == 1
    idx = repetition_num[@deno] = ar[1].size - ar[2]
    output_st(ar, idx, n)
  end
  
  def get_rcycle
    quotient = []
    remainder = []
    divided = @nume - (@nume / @deno) * @deno
    loop do
      quotient << divided / @deno
      a = divided % @deno
      return [quotient] if a.zero?
      if (b = remainder.index(a))
        return [quotient, remainder, b]
      end
      remainder << a
      divided = a * 10
    end
  end

  def output_st(ar, idx, n)
    st = ar[0].join[1..-1]
    if (ln = st.length) > idx
      idx = ln - idx
      "#{n}.#{st[0..(idx - 1)]}(#{st[idx..-1]})"
    else
      "#{n}.(#{st})"
    end
  end
  private :main, :get_rcycle, :output_st
end

#整数を2数の積に分ける/約数を求める
class Integer
  def divide2(include1=false)
    ar = []
    s = include1 ? 1 : 2 
    for i in s..(self ** 0.5)
      ar.push([i, self / i]) if (self % i).zero?
    end
    ar
  end
  
  def divisors_int
    divide2(true).flatten.uniq.sort
  end
end

class Float
  def integer?
    (self - self.to_i).zero?
  end
end

#多重配列を簡単に生成する
class Array
  def self.make(ar, ob=nil)
    raise "Argument class Error" unless ar.class == Array
    a = ar.dup
    ar1 = []
    a.shift.times {ar1 << (a.empty? ? (ob.dup rescue ob) : Array.make(a, ob))}
    ar1
  end
end

#一文字入力
module Utils
  def key_wait
    c = nil
    loop {break if (c = STDIN.getch)}
    STDIN.cooked!
    c
  end
  module_function :key_wait
end

#配列のディープコピー
class Object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

#階乗
class Integer
  def factorial
    return 1 if zero?
    ans = 1
    downto(2) {|i| ans *= i}
    ans
  end
end

#マイクロ秒まで採った現在時刻を、アルファベットの辞書順になるように変換して出力する
module Utils
  def time_lexic
    t = Time.now
    i = (t.to_i.to_s + sprintf("%06d", t.usec)).to_i
    ar = ("a".."z").to_a
    st = ""
    begin
      st = ar[i % 26] + st
      i /= 26
    end while i > 0
    st
  end
  module_function :time_lexic
end

#配列の要素aをすべてbで置き換える
class Array
  def change!(a, b)
    map! {|i| (i == a) ? b : i}
  end
  
  def change(a, b)
    map {|i| (i == a) ? b : i}
  end
end

#順列と組み合わせ
module Utils
  def permutation(a, b)
    a.factorial / (a - b).factorial
  end
  
  def combination(a, b)
    return 1 if a == b or b.zero?
    a.factorial / ((a - b).factorial * b.factorial)
  end
  module_function :permutation, :combination
end

#末尾呼び出しの回避
module Utils
  def trcall(value)
    while value.instance_of?(Proc)
      value = value.call
    end
    value
  end
  module_function :trcall
end

class Module
  def tco(meth)
    called = false
    tmp = nil
    
    orig_meth = "orig_#{meth}"
    alias_method orig_meth, meth
    private orig_meth
    
    define_method(meth) do |*args|
      unless called
        called = true
        args = tmp until result = send(orig_meth, *args)
        result
      else
        tmp = args
        false
      end
    end
  end
end

#selfをブロック内で処理して返す
class Object
  def flow
    return yield(self)
  end
end

#フォルダ名、ファイル名に使っていけない文字を消去する
class String
  def fname_filter
    gsub!(%r!(:|\/|\*|\?|\"|<|>|\\)!, "")
    self
  end
end

#Zコンビネータ
module Utils
  Z = ->(f) {
    ->(x){
      f[ ->(y) {x[x][y]} ]
    }[
      ->(x){
        f[ ->(y) {x[x][y]} ]
      }
    ]
  }
end

class Object
  def nil_trans(obj = "")
    (self == nil) ? obj : self
  end
end

class Counter
  def self.make(mname, counter = 0, step = 1)
    f = true
    counter -= step
    Object.class_eval do
      define_method(mname) do |*arg|
        if arg.size >= 1
          counter += step if f
          counter += arg[0]
        else
          counter += step
        end
        f = false
        counter
      end
    end
  end
end

module Enumerable
  def map_to_h(&bl)
    map(&bl).to_h
  end
end

class Hash
  def collect_keys(value)
    each_key.select {|k| self[k] == value}
  end
end

class Integer
  def times_retry(message: true, wait: 0)
    n = 1
    begin
      yield(n)
    rescue => e
      if n <= self
        puts "Error: retry #{n}" if message
        puts e.backtrace if message
        n += 1
        sleep(wait)
        retry
      end
      puts "Error: stop" if message
      raise e
    end
  end
end

#プログレスバーの表示
module Utils
  def progress_bar
    w = Gtk::Window.new
    w.signal_connect("destroy") {Gtk.main_quit}
    w.set_size_request(300, 50)
    w.border_width = 10
    w.title = "Progress"
    
    bar = Gtk::ProgressBar.new
    w.add(bar)
  
    Thread.new(bar) do |bar|
      yield(bar)
    end
      
    w.show_all
    Gtk.main
  end
  module_function :progress_bar
end

module Utils
  #画像ファイルでなければ削除
  def delete_non_img(fname)
    if Utils.imgexist?(fname)
      false
    else
      FileUtils.rm(fname)
      true
    end
  end
  module_function :delete_non_img
  
  #指定したディレクトリの空フォルダを削除
  def delete_empty_folder(fname = './')
    Dir.chdir(fname)
    Dir.glob("*").each do |name|
      next unless File.directory?(name)
      Dir.rmdir(p name) if Dir.glob("./#{name}/*").empty? rescue next
    end
  end
  module_function :delete_empty_folder
end

#ベルを鳴らす
module Utils
  def bell
    `paplay /usr/share/sounds/freedesktop/stereo/complete.oga`
  end
  module_function :bell
end
