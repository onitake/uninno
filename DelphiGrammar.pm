package DelphiGrammar;

use strict;
use Marpa::R2;

our $GRAMMAR = <<'END_OF_SOURCE';

	:start ::= <unit>
	:discard ~ <ignore>
	:default ::= action => ::array bless => ::lhs

	<ignore> ~ <ws> | <comment>
	<ws> ~ [\s]+
	<comment> ~ '{' <comment string> '}' | '(*' <comment string> '*)'
	<comment string> ~ [^}]*
	
	<comma> ~ ','
	<semicolon> ~ ';'
	<dot> ~ '.'

	<letter> ~ [A-Za-z]
	<digit> ~ [0-9]
	<hex digit> ~ [0-9A-Fa-f]
	<underscore> ~ [_]
	
	<identifier> ~ <letter underscore> <identifier suffix>
	<identifier suffix> ~ <letter underscore digit>*
	<letter underscore> ~ <letter> | <underscore>
	<letter underscore digit> ~ <letter underscore> | <digit>
	
	<qualified identifier> ::= <identifier>+ separator => <dot> proper => 1 bless => list
	
	<digit sequence> ~ <digit>+
	<hex digit sequence> ~ <hex digit>+
	<unsigned integer terminal> ~ <digit sequence> | '$' <hex digit sequence>
	<unsigned integer> ~ <unsigned integer terminal>
	<sign terminal> ~ '+' | '-'
	<sign> ~ <sign terminal>
	<unsigned real> ~ <digit sequence> | <digit sequence> '.' <digit sequence> | <digit sequence> <scale factor> | <digit sequence> '.' <digit sequence> <scale factor>
	<scale factor> ~ [Ee] <sign terminal> <digit sequence> | [Ee] <digit sequence>
	<unsigned number terminal> ~ <unsigned integer terminal> | <unsigned real>
	<unsigned number> ~ <unsigned number terminal>
	
	<character string> ::= <character string entry>+
	<character string entry> ~ <quoted string> | <control string>
	<quoted string> ~ ['] <string character list> [']
	<string character> ~ [^\n']
	<string character list> ~ <string character>*
	<control string> ~ '#' <unsigned integer terminal>
	
	<unit> ::= <unit heading> ';' <interface part> <implementation part> <initialization part> '.'
	<unit heading> ::= 'unit' <identifier> bless => defer1

	<interface part> ::= 'interface' <uses clause> <interface part list> | 'interface' <interface part list>
	<interface part list> ::= <interface part entry>* bless => list
	<interface part entry> ::= <constant declaration part> bless => defer0 | <type declaration part> bless => defer0
	#<interface part entry> ::= <constant declaration part> | <type declaration part> | <variable declaration part> | <procedure and function heading_part>

	<implementation part> ::= 'implementation' <uses clause> | 'implementation'
	#<implementation part> ::= 'implementation' <uses clause> <declaration part> | 'implementation' <declaration part>

	<initialization part> ::= 'end' bless => empty
	#<initialization part> ::= 'initialization' <statement list> 'end' | 'end'

	<uses clause> ::= 'uses' <identifier list> ';' bless => defer1

	<identifier list> ::= <identifier>+ separator => <comma> proper => 1 bless => list
	
	<constant declaration part> ::= 'const' <constant declaration list> bless => defer1
	<constant declaration list> ::= <constant declaration entry>+ bless => list
	<constant declaration entry> ::= <constant declaration> bless => defer0 | <typed constant declaration> bless => defer0
	
	<type declaration part> ::= 'type' <type declaration list> bless => defer1
	<type declaration list> ::= <type declaration>+ bless => list
	
	<constant declaration> ::= <identifier> '=' <constant> ';'
	<constant> ::= <expression> bless => defer0
	
	<factor> ::= <variable reference> | <unsigned constant> | '(' <expression> ')' | 'not' <factor> | <sign> <factor> | <function call> | <value typecast> | <address factor>
	<unsigned constant> ::= <unsigned number> bless => defer0 | <character string> bless => defer0 | <identifier> bless => defer0
	<term> ::= <term list> <factor>
	<term list> ::= <term entry>*
	<term entry> ::= <factor> '*' | <factor> '/' | <factor> 'div' | <factor> 'mod' | <factor> 'and' | <factor> 'shl' | <factor> 'shr' | <factor> 'as'
	<simple expression> ::= <simple expression list> <term>
	<simple expression list> ::= <simple expression entry>*
	<simple expression entry> ::= <term> '+' | <term> '-' | <term> 'or' | <term> 'xor'
	<expression> ::= <simple expression> <expression comparison> | <simple expression>
	<expression comparison> ::= '<' <simple expression> | '<=' <simple expression> | '>' <simple expression> | '>=' <simple expression> | '=' <simple expression> | '<>' <simple expression> | 'in' <simple expression> | 'is' <simple expression>

	<typed constant declaration> ::= <identifier> ':' <type> '=' <typed constant> ';'
	<typed constant> ::= <constant> bless => defer0 | <array constant> bless => defer0 | <record constant> bless => defer0 | <procedural constant> bless => defer0
	#<typed constant> ::= <constant> | <address constant> | <array constant> | <record constant> | <procedural constant>
	
	<type declaration> ::= <identifier> '=' <type> ';'
	<type> ::= <simple type> bless => defer0 | <string type> bless => defer0 | <structured type> bless => defer0 | <pointer type> bless => defer0 | <procedural type> bless => defer0 | <identifier> bless => defer0

	<simple type> ::= <ordinal type> bless => defer0 | <real type> bless => defer0
	<real type> ::= <real type identifier> bless => defer0
	<real type identifier> ::= 'Real' | 'Single' | 'Double' | 'Extended' | 'Comp'
	
	<ordinal type> ::= <subrange type> bless => defer0 | <enumerated type> bless => defer0 | <ordinal type identifier> bless => defer0
	<ordinal type identifier> ::= 'Integer' | 'ShortInt' | 'SmallInt' | 'LongInt' | 'Byte' | 'Word' | 'Cardinal' | 'Boolean' | 'ByteBool' | 'WordBool' | 'LongBool' | 'Char'
	
	<enumerated type> ::= '(' <identifier list> ')' 
	
	<subrange type> ::= <constant> '..' <constant>

	<string type> ::= 'String' | 'String' '[' <unsigned integer> ']'
	
	<structured type> ::= 'packed' <structured type list> | <structured type list>
	<structured type list> ::= <array type> bless => defer0 | <record type> bless => defer0 | <identifier> bless => defer0 | <class reference type> bless => defer0 | <set type> bless => defer0 | <file type> bless => defer0
	
	<array type> ::= 'array' '[' <index list> ']' 'of' <type>
	<index list> ::= <type>+ separator => <comma> proper => 1 bless => list
	
	<pointer type> ::= '^' <base type> | 'PChar'
	<base type> ::= <identifier> bless => defer0
	
	<procedural type> ::= 'procedure' | 'procedure' <formal parameter list> | 'procedure' 'of' 'object' | 'procedure' <formal parameter list> 'of' 'object' | 'function' ':' <result type> | 'function' <formal parameter list> ':' <result type> | 'function' ':' <result type> 'of' 'object' | 'function' <formal parameter list> ':' <result type> 'of' 'object'
	
	<formal parameter list> ::= '(' <parameter declaration list> ')'
	<parameter declaration list> ::= <parameter declaration>+ separator => semicolon proper => 1 bless => list
	<parameter declaration> ::= <identifier list> | 'var' <identifier list> | 'const' <identifier list> | <identifier list> ':' <parameter type> | 'var' <identifier list> ':' <parameter type> | 'const' <identifier list> ':' <parameter type> | <identifier list> ':' 'array' 'of' <parameter type> | 'var' <identifier list> ':' 'array' 'of' <parameter type> | 'const' <identifier list> ':' 'array' 'of' <parameter type>;
	
	<parameter type> ::= <identifier> bless => defer0
	<result type> ::= <identifier> bless => defer0
	
	<record type> ::= 'record' <field list> 'end' | 'record' 'end'
	<field list> ::= <fixed part> | <fixed part> ';' <variant part> | <variant part> | <fixed part> ';' | <fixed part> ';' <variant part> ';' | <variant part> ';'
	<fixed part> ::= <fixed fragment>+ separator => semicolon proper => 1
	<fixed fragment> ::= <identifier list> ':' <type>
	<variant part> ::= 'case' <tag field type> 'of' <variant list> | 'case' <identifier> ':' <tag field type> 'of' <variant list>
	<tag field type> ::= <identifier> bless => defer0
	<variant list> ::= variant+ separator => semicolon proper => 1 bless => list
	<variant> ::= <constant list> ':' '(' <field list> ')'
	<constant list> ::= <constant>+ separator => <comma> proper => 1 bless => list
	
	<set type> ::= 'set' 'of' <type>
	
	<file type> ::= 'file' | 'file' 'of' <type>
	
	<class reference type> ::= 'class' 'of' <identifier>
	
	<value typecast> ::= <identifier> '(' expression ')'
	
	<address factor> ::= '@' <variable reference> | '@' <identifier> | '@' <qualified method identifier>
	
	<variable reference> ::= <identifier> | <variable typecast> | <expression> <qualifier> | <identifier> <qualifier list> | <variable typecast> <qualifier list> | <expression> <qualifier> <qualifier list>
	<qualifier list> ::= <qualifier>* bless => list
	
	<qualifier> ::= <index> | <field designator> | '^'
	<index> ::= '[' <expression list> ']'
	<expression list> ::= <expression>+ separator => <comma> proper => 1 bless => list
	<field designator> ::= '.' <identifier>
	
	<qualified method identifier> ::= <qualified identifier>

	<variable typecast> ::= <identifier> '(' <variable reference> ')'
	
	<function call> ::= <function call target> | <function call target> <actual parameter list>
	<function call target> ::= <identifier> | <method designator> | <qualified method designator> | <variable reference>
	<actual parameter list> ::= '(' <actual parameter items> ')'
	<actual parameter items> ::= <actual parameter>+ separator => <comma> proper => 1 bless => list
	<actual parameter> ::= <expression> | <variable reference>
	
	<method designator> ::= <identifier> | <variable reference> '.' <identifier>
	<qualified method designator> ::= <qualified identifier> '.' <method designator>
	
	<array constant> ::= '(' <typed constant list> ')' bless => defer1
	<typed constant list> ::= <typed constant>+ separator => <comma> proper => 1 bless => list
	
	<record constant> ::= '(' <record constant list> ')'
	<record constant list> ::= <record constant fragment>+ separator => <semicolon> proper => 1 bless => list
	<record constant fragment> ::= <identifier> ':' <typed constant>
	
	<procedural constant> ::= <identifier> | 'nil'
	
END_OF_SOURCE

sub G {
	my ($class, $action, $bless) = @_;
	$class = ref($class) if defined(ref($class));
	if (defined($action) && $action !~ /^::/) {
		$bless = $action;
		undef($action);
	}
	return Marpa::R2::Scanless::G->new({ default_action => $action, source => \$GRAMMAR, bless_package => $bless });
}

sub R {
	return Marpa::R2::Scanless::R->new({ grammar => shift->G(@_) });
}

1;
