require 'jsduck/util/singleton'

module JsDuck

  # Evaluates Esprima AST node into Ruby object
  class Evaluator
    include JsDuck::Util::Singleton

    # Converts AST node into a value.
    #
    # - String literals become Ruby strings
    # - Number literals become Ruby numbers
    # - Regex literals become :regexp symbols
    # - Array expressions become Ruby arrays
    # - etc
    #
    # For anything it doesn't know how to evaluate (like a function
    # expression) it throws exception.
    #
    def to_value(ast)
      case ast["type"]
      when "ArrayExpression"
        ast["elements"].map {|e| to_value(e) }
      when "ObjectExpression"
        h = {}
        ast["properties"].each do |p|
          key = key_value(p["key"])
          value = to_value(p["value"])
          h[key] = value
        end
        h
      when "BinaryExpression"
        if ast["operator"] == "+"
          left = to_value(ast["left"])
          right = to_value(ast["right"])
          if left[:type] == right[:type] && [:string, :number].include?(left[:type])
            {:type => left[:type], :value => left[:value] + right[:value]}
          elsif left[:type] == :string && right[:type] == :number
            {:type => :string, :value => left[:value].to_s + right[:value].to_s}
          elsif left[:type] == :number && right[:type] == :string
            {:type => :string, :value => left[:value].to_s + right[:value].to_s}
          end
        else
          throw "Unable to handle operator: " + ast["operator"]
        end
      when "MemberExpression"
        if base_css_prefix?(ast)
          "x-"
        else
          throw "Unable to handle this MemberExpression"
        end
      when "Literal"
        if ast["raw"] =~ /\A\//
          {:type => :regexp, :value => ast["raw"]}
        else
          {:type => literal_value_type(ast["value"]), :value => ast["value"]}
        end
      else
        throw "Unknown node type: " + ast["type"]
      end
    end

    def literal_value_type(v)
      if v.is_a?(String)
        :string
      elsif v.is_a?(Numeric)
        :number
      elsif v == true || v == false
        :boolean
      else
        nil
      end
    end

    # Turns object property key into string value
    def key_value(key)
      key["type"] == "Identifier" ? key["name"] : key["value"]
    end

    # True when MemberExpression == Ext.baseCSSPrefix
    def base_css_prefix?(ast)
      ast["computed"] == false &&
        ast["object"]["type"] == "Identifier" &&
        ast["object"]["name"] == "Ext" &&
        ast["property"]["type"] == "Identifier" &&
        ast["property"]["name"] == "baseCSSPrefix"
    end

    def typeof(ast)
      if undefined?(ast) || void?(ast)
        :undefined
      elsif this?(ast)
        :this
      elsif boolean?(ast)
        :boolean
      elsif string?(ast)
        :string
      elsif regexp?(ast)
        :regexp
      else
        :other
      end
    end

    def undefined?(ast)
      ast["type"] == "Identifier" && ast["name"] == "undefined"
    end

    def void?(ast)
      ast["type"] == "UnaryExpression" && ast["operator"] == "void"
    end

    def this?(ast)
      ast["type"] == "ThisExpression"
    end

    def boolean?(ast)
      if boolean_literal?(ast)
        true
      elsif ast["type"] == "UnaryExpression" || ast["type"] == "BinaryExpression"
        !!BOOLEAN_RETURNING_OPERATORS[ast["operator"]]
      elsif ast["type"] == "LogicalExpression"
        boolean?(ast["left"]) && boolean?(ast["right"])
      elsif ast["type"] == "ConditionalExpression"
        boolean?(ast["consequent"]) && boolean?(ast["alternate"])
      elsif ast["type"] == "AssignmentExpression" && ast["operator"] == "="
        boolean?(ast["right"])
      else
        false
      end
    end

    def boolean_literal?(ast)
      ast["type"] == "Literal" && (ast["value"] == true || ast["value"] == false)
    end

    def string?(ast)
      if string_literal?(ast)
        true
      elsif ast["type"] == "BinaryExpression" && ast["operator"] == "+"
        string?(ast["left"]) || string?(ast["right"])
      elsif ast["type"] == "UnaryExpression" && ast["operator"] == "typeof"
        true
      else
        false
      end
    end

    def string_literal?(ast)
      ast["type"] == "Literal" && ast["value"].is_a?(String)
    end

    def regexp?(ast)
      ast["type"] == "Literal" && ast["raw"] =~ /^\//
    end

    BOOLEAN_RETURNING_OPERATORS = {
      "!" => true,
      ">" => true,
      ">=" => true,
      "<" => true,
      "<=" => true,
      "==" => true,
      "!=" => true,
      "===" => true,
      "!==" => true,
      "in" => true,
      "instanceof" => true,
      "delete" => true,
    }

  end

end

