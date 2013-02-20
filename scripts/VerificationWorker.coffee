
importScripts(
  '../formats/WKS.js'
  '../formats/WCCS.js'
  '../formats/WCTL.js'
  '../formats/WKSParser.js'
  '../formats/WCCSParser.js'
  '../formats/WCTLParser.js'
  '../engines/NaiveEngine.js'
  '../engines/SymbolicEngine.js'
)

self.onmessage = (e) ->
  {model, mode, state, property, engine, encoding} = e.data

  formula = WCTLParser.parse property
  wks     = self["#{mode}Parser"].parse model
  state   = wks.getStateByName state
  cval    = true        if encoding is 'Naive'
  cval    = 0           if encoding is 'Symbolic'
  method  = 'local'     if engine is 'Local'
  method  = 'global'    if engine is 'Global'
  engine  = new self["#{encoding}Engine"](formula, state)

  val = engine[method]()

  self.postMessage(val is cval)