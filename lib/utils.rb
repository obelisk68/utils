require "utils/version"
require 'open-uri'
require 'fastimage'

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
  
  def self.imgexist?(url)
    FastImage.size(url)
  end
  
  def self.getfile(url, filename, max=0)
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
end
  
class String 
  def imgsuffix
    [".jpg", ".gif", ".png", ".jpeg", ".bmp", ".JPG", ".GIF", ".PNG", ".JPEG", ".BMP"].each do |sf|
      return sf if include?(sf)
    end
    ""
  end
end

#任意の階層だけ繰り返しをネストする
class Array
  def nest_loop(&bk)
    nsloop(self, [], &bk)
  end
  
  private
  def nsloop(ar1, ar2, &bk)
    tmp1 = ar1.dup
    time = tmp1.shift
    unless time
      bk.call(ar2)
    else
      time.times do |i|
        tmp2 = ar2.dup
        tmp2.push(i)
        nsloop(tmp1, tmp2, &bk)
      end
    end
  end
end

