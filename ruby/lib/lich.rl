%%{
  machine lich;

  action missing_size_prefix {
    raise MissingSizePrefix.new(p)
  }

  action size_enter {
    size_start = p
  }
  action size_leave {
    @size = data[size_start..p].pack('c*').to_i
    raise ExcessiveSizePrefix.new(p+1) if @size > 18446744073709551615
  }

  action store_token {
    raise IncompleteData.new(pe) if p+@size+1 > pe
    raise MissingClosingMarker.new(pe) if p+@size+1 == pe
    range = (p..p+@size+1)
    token = current.add_child(range)
    if token.markers != '<>'
      pe = range.end
      current = token
      fgoto main;
    else
      p = range.end
    end
  }

  size = digit{1,20};
  element = size >size_enter @size_leave /[<[{]/ @store_token;
  main := element* >!missing_size_prefix;
}%%

module Lich
  class Error < Exception
    attr_reader :index

    def initialize(index)
      @index = index
    end
  end

  class MissingSizePrefix < Error; end
  class MissingClosingMarker < Error; end
  class IncompleteData < Error; end
  class IncorrectClosingMarker < Error; end
  class ExcessiveSizePrefix < Error; end

  class Token
    Types = {
      '<>' => lambda {|token| token.data[token.range].pack('c*') },
      '[]' => lambda {|token| token.children.map(&:to_obj) },
      '{}' => lambda {|token| Hash[*token.children.map(&:to_obj)] }
    }

    attr_reader :data, :range, :markers
    attr_reader :children, :parent

    def initialize(data, range=nil, parent=nil)
      @data = data
      @range = range
      @parent = parent
      @children = []

      if range
        @markers = data.values_at(@range.begin, @range.end).map(&:chr).join
        raise IncorrectClosingMarker.new(@range.end) unless Types.has_key?(@markers)

        @range = (@range.begin+1..@range.end-1)
      end
    end

    def add_child(range)
      token = Token.new(data, range, self)
      children << token
      token
    end

    def to_obj
      if @markers
        Types[@markers][self]
      else
        obj = children.map(&:to_obj)
        (obj.length == 1) ? obj[0] : obj
      end
    end
  end

  %% write data;

  class << self
    def load(data)
      data = data.unpack('c*') if data.respond_to?(:unpack)
      range = (0..data.length)
      eof = range.end

      head = Token.new(data)
      current = head

      while true
        %% write init;
        %% write exec;

        return head.to_obj if pe == eof

        current = current.parent
        p += 1
        pe = current.range.end + 1 rescue eof
      end
    end
  end
end
