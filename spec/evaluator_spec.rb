require "jsduck/js_parser"
require "jsduck/evaluator"

describe "JsDuck::Evaluator#typeof" do
  def typeof(string)
    node = JsDuck::JsParser.new('/** */ (' + string + ');').parse[0]
    return JsDuck::Evaluator.typeof(node[:code]["expression"])
  end

  describe "returns :undefined when" do
    it "variable named undefined" do
      typeof("undefined").should == :undefined
    end

    it "'void' statement" do
      typeof("void(blah)").should == :undefined
    end
  end

  describe "returns :boolean when" do
    it "true" do
      typeof("true").should == :boolean
    end

    it "false" do
      typeof("false").should == :boolean
    end

    it "negation" do
      typeof("!foo").should == :boolean
    end

    it "> comparison" do
      typeof("x > y").should == :boolean
    end

    it "<= comparison" do
      typeof("x <= y").should == :boolean
    end

    it "== comparison" do
      typeof("x == y").should == :boolean
    end

    it "'in' expression" do
      typeof("key in object").should == :boolean
    end

    it "'instanceof' expression" do
      typeof("obj instanceof cls").should == :boolean
    end

    it "'delete' expression" do
      typeof("delete foo[bar]").should == :boolean
    end

    it "conjunction of boolean expressions" do
      typeof("x > y && y > z").should == :boolean
    end

    it "disjunction of boolean expressions" do
      typeof("x == y || y == z").should == :boolean
    end

    it "conditional expression evaluating to boolean" do
      typeof("x ? true : a > b").should == :boolean
    end

    it "assignment of boolean" do
      typeof("x = true").should == :boolean
    end
  end

  describe "returns :string when" do
    it "string literal" do
      typeof("'foo'").should == :string
    end

    it "string concatenation" do
      typeof("'foo' + 'bar'").should == :string
    end

    it "string concatenated with number" do
      typeof("'foo' + 7").should == :string
    end

    it "number concatenated with string" do
      typeof("8 + 'foo'").should == :string
    end

    it "typeof expression" do
      typeof("typeof 8").should == :string
    end
  end

  describe "returns :regexp when" do
    it "regex literal" do
      typeof("/.*/").should == :regexp
    end
  end

end


describe "JsDuck::Evaluator#to_value" do
  def to_value(string)
    node = JsDuck::JsParser.new('/** */ (' + string + ');').parse[0]
    return JsDuck::Evaluator.to_value(node[:code]["expression"])[:value]
  end

  it "returns true when true literal" do
    to_value("true").should == true
  end

  it "returns false when false literal" do
    to_value("false").should == false
  end

  it "returns 'foo' when 'foo' string literal" do
    to_value("'foo'").should == 'foo'
  end

  it "returns the concatenated string on string concatenation" do
    to_value("'foo' + 'bar'").should == 'foobar'
  end

  it "returns resulting string when string concatenated with number" do
    to_value("'foo' + 7").should == 'foo7'
  end

  it "returns resulting string when number concatenated with string" do
    to_value("8 + 'foo'").should == '8foo'
  end

  it "returns the regex as string when regex literal" do
    to_value("/.*/").should == '/.*/'
  end

end
