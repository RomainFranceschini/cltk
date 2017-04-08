require "./named_tuple_extensions"
require "json"

# This class is a good start for all your abstract syntax tree node needs.
#
# declare an ASTNode by subclassing it
#
# ```
# require "cltk/ast"
#
# abstract class MyLanguageValue < CLTK::ASTNode; end
#
# class MyLanguageVariable < CLTK::ASTNode
#   values({name: String, value: MyLanguageValue})
# end
#
# class MyLanguageString < MyLanguageValue
#   values({text: String})
# end
#
# class MyLanguageStringInterpolated < MyLanguageString
#   values({variables: Array(MyLanguageVariable)})
# end
#
# country_variable = MyLanguageVariable.new(
#   name: "country", value: MyLanguageString.new(text: "argentina")
# )
#
# # initialize takes all the values of class and it's ancestors
# interpolated_string = MyLanguageStringInterpolated.new(
#   text: "user is from \#\{country\}.", variables: [country_variable]
# )
#
# puts interpolated_string.to_pretty_json
# # {
# #   "text": "user is from #{country}.",
# #   "variables": [
# #     {
# #       "name": "country",
# #       "value": {
# #         "text": "argentina"
# #       }
# #     }
# #   ]
# # }
# ```
abstract class CLTK::ASTNode

  def initialize(**options)
    if options.size > 0
      raise "superfluos options provided : #{options}"
    end
  end

  def eval
    self
  end

  def inspect
    "#{self.class.name}(" +
      if vs = values
        vs.map do |k, v|
          value = if v.is_a?(Array)
                    "[" +
                      v.map{ |vv| vv.inspect.as(String) }.join(", ") +
                      "]"
                  elsif v.is_a?(Hash)
                    "{" +
                      v.map{ |kk, vv| "#{kk.inspect}: #{vv.inspect}".as(String) }.join(", ") +
                      "}"
                  else
                    v.inspect
                  end
          "#{k}: #{value}"
        end.join(", ")
      else
        ""
      end + ")"
  end

  def to_json
    values.to_json
  end

  def to_json(json : ::JSON::Builder)
    values.to_json(json)
  end

  def to_pretty_json
    values.to_pretty_json
  end

  def to_pretty_json(json : ::JSON::Builder)
    values.to_pretty_json(json)
  end

  # a macro to define the values this ASTNode should take. defines getters and setters as well as the right initialize method
  macro values(values)
    @{{@type.name.downcase.gsub(/:/, "")}}_values:  {{values}}

    def values
      own_values = { {% for key, index in values.keys%}{% if  values[key].stringify.starts_with? "Array" %}{{key}}: (@{{@type.name.downcase.gsub(/:/, "")}}_values[:{{key}}].as(Array)).map { |e| e.as({{values[key].id.gsub(/^Array\(|\)$/, "")}})}{% else %}  {{key}}: @{{@type.name.downcase.gsub(/:/, "")}}_values[:{{key}}].as({{values.values[index]}}){% end %}{%if index < values.keys.size - 1%},
          {%end%}{% end %}
      }
      {% if @type.superclass.methods.any?{ |x| x.name == "values"} %}
        super_values = super
        if super_values
          super_values.merge(own_values)
        else
          own_values
        end
      {% else %}
        own_values
      {% end %}
    end

    def ==(other : self)
      self.values.values == other.values.values
    end

    {% for key, index in values %}

      def {{key}}
        @{{@type.name.downcase.gsub(/:/, "")}}_values[:{{key}}]
      end

      def {{key}}=(value : {{values[key]}})
        @{{@type.name.downcase.gsub(/:/, "")}}_values = { {% for tkey, index in values.keys%}
          {% if tkey == key %}{{tkey}}: value{% else %}{{tkey}}: @{{@type.name.downcase.gsub(/:/, "")}}_values[:{{tkey}}].as({{values.values[index]}}){% end %}{%if index < values.keys.size - 1%},{%end%}{% end %}
        }
      end
    {% end %}

      {% if values.keys.size > 0 %}
        #        def initialize(@values); end

        def initialize(**options)
          @{{@type.name.downcase.gsub(/:/, "")}}_values = { {% for key, index in values.keys%}{% if  values[key].stringify.starts_with? "Array" %}{{key}}: (options[:{{key}}].as(Array)).map { |e| e.as({{values[key].id.gsub(/^Array\(|\)$/, "")}})}{% else %}  {{key}}: options[:{{key}}].as({{values.values[index]}}){% end %}{%if index < values.keys.size - 1%},
          {%end%}{% end %}
          }
          {% if !(@type.superclass.class.id =~ "ASTNode") %}
            rest = options - {{values}}
            if rest.size != 0
              super(**rest)
            end
          {% end %}
        end
      {% end %}

  end

  macro inherited

    {%if !@type.abstract? %}
      def_clone
    {% end %}

    def values
      {% if @type.superclass.methods.any?{ |x| x.name == "values"} %}
        super
      {% else %}
        nil
      {% end %}
    end

  end

  # this macro defines the given values as children by creating the accessor children
  macro as_children(values)
    def children
      { {% for key, index in values %}
                        {{key.id}}: values[:{{key.id}}]{% if index < values.size - 1 %},{% end %}
        {% end %} }
    end
  end

end
