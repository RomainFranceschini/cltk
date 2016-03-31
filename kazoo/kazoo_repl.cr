require "readline"
require "./klexer"
require "./kparser"
require "./kast"
require "./kscope"

lexer  = Kazoo::Lexer
parser = Kazoo::Parser
scope  = Kazoo::Scope(Expression).new

input = ""


while !(input).match /^exit$/
  begin

    # read input
    input = Readline.readline(":: ", true) || ""

    # lex input
    tokens = lexer.lex(input)

    # parse lexed tokens
    res = parser.parse(tokens, {:accept => :first}) as CLTK::ASTNode

    # evaluate the result with a given scope
    # (scope my be altered by the expression)
    evaluated =  res.eval_scope(scope).to_s

    # output result of evaluation
    puts evaluated

  rescue e: CLTK::LexingError
    show_lexing_error(e, input)
  rescue e: CLTK::NotInLanguage
    show_syntax_error(e,input)
  rescue e
    puts e
  end
end

def show_lexing_error(e, input)
  puts "Lexing error at:\n\n"
  puts "    " + input.split("\n")[e.line_number-1]
  puts "    " + e.line_offset.times().map { "-" }.join + "^"
  puts e
end

def show_syntax_error(e,input)
    pos = e.current.position
    if pos
      puts "Syntax error at:"
      puts "    " + input.split("\n")[pos.line_number-1]
      puts "    " + pos.line_offset.times().map { "-" }.join + "^"
    else
      puts "invalid input: #{input}"
    end
end
