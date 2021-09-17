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
    s = source.gsub(/\//, '\/')
    "/#{s}/"
  end
end

class PosixMatchData
  class << self
    # Cannot be instanciate from Ruby space
    undef new
  end


end

class PosixRegexpError < RegexpError
end

Regexp = PosixRegexp unless Object.const_defined? :Regexp
MatchData = PosixMatchData unless Object.const_defined? :MatchData
