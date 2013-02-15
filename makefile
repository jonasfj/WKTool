all:
	jison WCTLParser.jison
	jison WKSParser.jison
	pegjs WCCSParser.pegjs
	coffee -c .
clean:
	rm *.js
