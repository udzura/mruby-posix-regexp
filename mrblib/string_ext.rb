# From: https://github.com/WindProphet/mruby-pure-regexp/blob/master/mrblib/string.rb
class String
  alias_method :orig_gsub,  :gsub
  alias_method :orig_gsub!, :gsub!
  alias_method :orig_sub,   :sub
  alias_method :orig_sub!,  :sub!

  def scan(reg, &block)
    a = []
    offset = 0
    while !(m = reg.match(self, offset)).nil?
      c = m.captures
      if c.empty?
        if block_given?
          yield(m.to_s)
        else
          a << m.to_s
        end
      else
        if block_given?
          yield(*c)
        else
          a << c
        end
      end
      offset = m.end(0)
    end
    if block_given?
      self
    else
      a
    end
  end

  def =~(regex)
    regex =~ self
  end

  def gsub(*args, &block)
    if args[0].is_a? Regexp
      raise ArgumentError.new("wrong number of arguments") unless args.size == 2
      ref = PosixRegexp::ReplaceCapture.new(args[1])
      str = ""
      index = 0
      while !(m = args[0].match(self, index)).nil?
        str += (m.pre_match[index..-1] || "") + ref.to_s(m)
        len = m.begin(0) - index + m.to_s.length
        if len == 0
          len = 1
          n = self[index]
          str += n unless n.nil?
        end
        break if m.begin(0) - index < 0
        index += len
      end
      str += self.byteslice(index..-1) if index < self.bytesize
      str
    else
      orig_gsub(*args, &block)
    end
  end

  def gsub!(*args, &block)
    if args[0].is_a? Regexp
      self.replace(gsub(*args, &block))
      self
    else
      orig_gsub!(*args, &block)
    end
  end

  def sub(*args, &block)
    if args[0].is_a? Regexp
      raise ArgumentError.new("wrong number of arguments") unless args.size == 2
      ref = PosixRegexp::ReplaceCapture.new(args[1])
      m = args[0].match(self)
      return self if m.nil?
      m.pre_match + ref.to_s(m) + m.post_match
    else
      orig_sub(*args, &block)
    end
  end

  def sub!(*args, &block)
    if args[0].is_a? Regexp
      self.replace(sub(*args, &block))
      self
    else
      orig_sub!(*args, &block)
    end
  end
end

class PosixRegexp
  class ReplaceCapture
    META = ['`', '\'', '+', '&']

    def initialize(string)
      raise TypeError.new("can't convert #{string.class.name} into String") unless string.is_a? String
      @template = []

      meta = false

      i = 0
      while i < string.length
        c = string[i]
        case c
        when '\\'
          if meta
            @template << c
          end
          meta = !meta
        when 'k'
          if meta
            if string[i+1] == '<'
              e = string.index('>')
              raise "invalid group name reference format" if e.nil?
              @template << string[(i+2)..(e-1)].to_sym
              i = e
            else
              @template << '\k'
            end
          else
            @template << c
          end
        when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
          if meta
            @template << [c.to_i]
          else
            @template << c
          end
          meta = false
        when *META
          if meta
            @template << [c]
          else
            @template << c
          end
        else
          if meta
            @template << c
          end
          @template << c
          meta = false
        end
        i += 1
      end
    end

    def to_s(matches)
      str = ""
      @template.each do |c|
        if c.is_a? Array
          c = c[0]
          case c
          when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
            s = matches[c.to_s.to_i]
            s = "" if s.nil?
            str += s
          when '`'
            str += matches.pre_match
          when '\''
            str += matches.post_match
          when '+'
            unless matches.captures.empty?
              str += matches.captures.last
            end
          when '&'
            str += matches[0]
          end
        elsif c.is_a? Symbol
          c = c.to_s
          unless matches.names.include?(c)
            raise IndexError.new("undefined group name reference: #{c}")
          end
          str += matches[c]
        else
          str += c
        end
      end
      str
    end
  end
end
