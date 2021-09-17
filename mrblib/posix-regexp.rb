class PosixRegexp
  # Called on literal compilation
  # @param string String
  # @param option String
  def self.compile(string, option = "")
    self.new(string, option || "")
  end

  attr_reader :source, :option
  alias options option

  def eql?(other)
    [source, options] == [other.source, other.options]
  end

  def ==(other)
    eql?(other)
  end

  def ===(string)
    !match(string).nil?
  end

  def =~(string)
    return nil if string.nil?
    m = match(string)
    m ? m.begin(0) : nil
  end

  def casefold?
    @option & REG_ICASE == REG_ICASE
  end

  $matchdata = []

  def inspect
    s = source.orig_gsub('/', '\/')
    "/#{s}/"
  end
end

class PosixMatchData
  class << self
    # Cannot be instanciate from Ruby space
    undef new
  end
  attr_reader :regexp, :string, :length
  alias size length

  def to_a
    m = (0...length).to_a.map do |i|
      @string[self.begin(i)...self.end(i)]
    end
    m[0] = "" if m[0].nil?
    m
  end

  def [](*args)
    to_a[*args]
  end

  def ==(other)
    [regexp, string, to_a] == [other.regexp, other.string, other.to_a]
  end

  def hash
    [@regexp, @string, to_a].hash
  end

  def captures
    a = to_a
    a.shift
    a
  end

  def pre_match
    string[0, self.begin(0)]
  end

  def post_match
    e = self.end(0)
    return "" if e.nil? || e >= string.length
    string[e, string.length - e]
  end

  def offset(n)
    [self.begin(n), self.end(n)]
  end

  def to_s
    to_a[0]
  end

  def values_at(*args)
    a = to_a
    args.map {|i| a[i] }
  end

  def inspect
    m = [to_s.inspect]
    i = 1
    captures.each do |c|
      m << "#{i}:#{c.inspect}"
      i += 1
    end
    "#<MatchData(Posix) #{m.join(' ')}>"
  end
end

class PosixRegexpError < RegexpError
end

Regexp = PosixRegexp unless Object.const_defined? :Regexp
MatchData = PosixMatchData unless Object.const_defined? :MatchData
