module GiavaScript
  class Environment
    @values : Hash(String, Value)
    @parent : Environment?

    def initialize(@parent : Environment? = nil)
      @values = Hash(String, Value).new
    end

    def has_key?(name : String) : Bool
      lookup(name)[:found]
    end

    def lookup(name : String) : NamedTuple(found: Bool, value: Value)
      current = self
      loop do
        values = current.values
        if values.has_key?(name)
          return {found: true, value: values[name]}
        end

        parent = current.parent
        return {found: false, value: UNDEFINED} unless parent

        current = parent
      end
    end

    def [](name : String) : Value
      lookup_result = lookup(name)
      return lookup_result[:value] if lookup_result[:found]

      raise KeyError.new(name)
    end

    def []=(name : String, value : Value) : Value
      @values[name] = value
    end

    protected getter values : Hash(String, Value)
    protected getter parent : Environment?
  end
end
