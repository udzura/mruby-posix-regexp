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
end

class PosixMatchData
end

class PosixRegexpError < RegexpError
end

Regexp = PosixRegexp unless Object.const_defined? :Regexp
MatchData = PosixMatchData unless Object.const_defined? :MatchData
