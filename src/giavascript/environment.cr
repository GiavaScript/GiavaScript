module GiavaScript
  class Environment
    @values : Hash(String, Value)
    @parent : Environment?

    def initialize(@parent : Environment? = nil)
      @values = Hash(String, Value).new
    end

    def has_key?(name : String) : Bool
      return true if @values.has_key?(name)
      return @parent.not_nil!.has_key?(name) if @parent

      false
    end

    def [](name : String) : Value
      if @values.has_key?(name)
        return @values[name]
      end

      if parent = @parent
        return parent[name]
      end

      raise KeyError.new(name)
    end

    def []=(name : String, value : Value) : Value
      @values[name] = value
    end
  end
end
