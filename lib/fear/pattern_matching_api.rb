module Fear
  # @api private
  module PatternMatchingApi
    # Creates pattern match. Use `case` method to
    # define matching branches. Branch consist of a
    # guardian, which describes domain of the
    # branch and function to apply to matching value.
    #
    # @example This mather apply different functions to Integers and to Strings
    #   matcher = Fear.matcher do |m|
    #     m.case(Integer) { |n| "#{n} is a number" }
    #     m.case(String) { |n| "#{n} is a string" }
    #   end
    #
    #   matcher.(42) #=> "42 is a number"
    #   matcher.("Foo") #=> "Foo is a string"
    #
    # if you pass something other than Integer or string, it will raise `Fear::MatchError`:
    #
    #     matcher.(10..20) #=> raises Fear::MatchError
    #
    # to avoid raising `MatchError`, you can use `else` method. It defines a branch matching
    # on any value.
    #
    #     matcher = Fear.matcher do |m|
    #       m.case(Integer) { |n| "#{n} is a number" }
    #       m.case(String) { |n| "#{n} is a string" }
    #       m.else  { |n| "#{n} is a #{n.class}" }
    #     end
    #
    #     matcher.(10..20) #=> "10..20 is a Range"
    #
    # You can use anything as a guardian if it responds to `#===` method:
    #
    #     m.case(20..40) { |m| "#{m} is within range" }
    #     m.case(->(x) { x > 10}) { |m| "#{m} is greater than 10" }
    #
    # If you pass a Symbol, it will be converted to proc using +#to_proc+ method
    #
    #     m.case(:even?) { |x| "#{x} is even" }
    #     m.case(:odd?) { |x| "#{x} is odd" }
    #
    # It's also possible to pass several guardians. All should match to pass
    #
    #     m.case(Integer, :even?) { |x| ... }
    #     m.case(Integer, :odd?) { |x| ... }
    #
    # If you want to perform pattern destruction, use +#xcase+ method
    #
    #     m.xcase('Date(year, 12, 31)') { |year:| "Last day of the year #{year}" }
    #
    # The pattern above ensures that it's 31 of December and extracts year to block named parameter
    #
    # Since matcher returns +Fear::PartialFunction+, you can combine matchers using
    # partial function API:
    #
    #     failures = Fear.matcher do |m|
    #       m.case('not_found') { ... }
    #       m.case('network_error') { ... }
    #     end
    #
    #     success = Fear.matcher do |m|
    #       m.case('ok') { ... }
    #     end
    #
    #     response = failures.or_else(success)
    #
    # @yieldparam matcher [Fear::PartialFunction]
    # @return [Fear::PartialFunction]
    # @see Fear::OptionPatternMatch for example of custom matcher
    def matcher(&block)
      PatternMatch.new(&block)
    end

    # Pattern match against given value
    #
    # @example
    #   Fear.match(42) do |m|
    #     m.case(Integer, :even?) { |n| "#{n} is even number" }
    #     m.case(Integer, :odd?) { |n| "#{n} is odd number" }
    #     m.case(Strings) { |n| "#{n} is a string" }
    #     m.else { 'unknown' }
    #   end #=> "42 is even number"
    #
    # @param value [any]
    # @yieldparam matcher [Fear::PartialFunction]
    # @return [any]
    def match(value, &block)
      matcher(&block).call(value)
    end

    # Creates partial function defined on domain described with guards
    #
    # @example
    #   pf = Fear.case(Integer) { |x| x / 2 }
    #   pf.defined_at?(4) #=> true
    #   pf.defined_at?('Foo') #=> false
    #
    # @example multiple guards combined using logical "and"
    #   pf = Fear.case(Integer, :even?) { |x| x / 2 }
    #   pf.defined_at?(4) #=> true
    #   pf.defined_at?(3) #=> false
    #
    # @note to make more complex matches, you are encouraged to use Qo gem.
    # @see Qo https://github.com/baweaver/qo
    # @example
    #   Fear.case(Qo[age: 20..30]) { |_| 'old enough' }
    #
    # @param guards [<#===, symbol>]
    # @param function [Proc]
    # @return [Fear::PartialFunction]
    def case(*guards, &function)
      PartialFunction.and(*guards, &function)
    end

    # Creates partial function defined on domain described with guard
    # and perform pattern extraction.
    #
    # @param pattern [String] pattern to match against
    # @param guards [<#===>] other guards against extracted pattern
    # @yieldparam hash [{Symbol => any}]
    # @return [Fear::PartialFunction]
    #
    # @example
    #   pf = Fear.xcase('['ok', Some(body)]') { |body:| ...  }
    #   pf.defined_at?(['ok', Fear.some(body)]) #=> true
    #   pf.defined_at?(['err', Fear.none]) #=> false
    #
    # @example pattern and guards. It matches against non-empty body
    #
    #   pf = Fear.xcase('['ok', Some(body)]', ->(body:) { !body.empty? }) { }
    #
    def xcase(pattern, *guards, &function)
      guard = Fear[pattern]
      extractor = self.case(guard) { |arg| guard.extracted_arguments(arg) }
      extractor.and_then(self.case(*guards, &function))
    end
  end
end
