all:
	jison WCTLParser.jison
	jison WKSParser.jison
	coffee -c .
clean:
	rm *.js
