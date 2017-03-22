require "spec"
require "../../src/cltk/lexers/calculator"
require "../../src/cltk/parser/parser"
require "../../src/cltk/parser/type"
require "../../../src/cltk/macros"

insert_output_of("crystalized Parser") do
  require "../../src/cltk/parser/crystalize"
  require "../../src/cltk/parser/type"
  require "../../src/cltk/parser"

  class CrystalizeAmbiguousParserExample < CLTK::Parser
    production(:e) do
      clause("NUM") {|n| n.as(Int32)}

      clause("e PLS e") { |e0, op, e1 | e0.as(Int32) + e1.as(Int32) }
      clause("e SUB e") { |e0, op, e1 | e0.as(Int32) - e1.as(Int32) }
      clause("e MUL e") { |e0, op, e1 | e0.as(Int32) * e1.as(Int32) }
      clause("e DIV e") { |e0, op, e1 | e0.as(Int32) / e1.as(Int32) }

    end

    finalize
    crystalize
  end
end

describe "CLTK::Parser::Parser.crystalize" do
  it "test_ambiguous_grammar" do
    actual = CrystalizeAmbiguousParserExample.parse(
      CLTK::Lexers::Calculator.lex("1 + 2 * 3"), {accept: :all}
    )
    actual.should eq [9,7]
  end
end
