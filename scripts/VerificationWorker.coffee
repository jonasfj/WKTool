
importScripts(
  '../lib/buckets.min.js'
  '../engines/Strategies.js'
  '../formats/WKS.js'
  '../formats/WCCS.js'
  '../formats/WCTL.js'
  '../formats/WKSParser.js'
  '../formats/WCCSParser.js'
  '../formats/WCTLParser.js'
  '../engines/NaiveEngine.js'
  '../engines/SymbolicEngine.js'
  '../engines/MinMaxEngine.js'
)

self.onmessage = (e) ->
  {model, mode, state, property, engine, encoding, strategy, expensive_stats} = e.data

  formula   = WCTLParser.parse property
  wks       = self["#{mode}Parser"].parse model
  wks.resolve()
  state     = wks.getStateByName state
  method    = 'local'     if engine is 'Local'
  method    = 'global'    if engine is 'Global'
  verifier  = new self["#{encoding}Engine"](formula, state)
  search_strategy = null
  if strategy?
    search_strategy = Strategies[strategy]

  start = (new Date).getTime()
  val = verifier[method](expensive_stats, search_strategy)
  time = ((new Date).getTime() - start)
  
  val['Time'] = time + " ms"
  val['TimeAsInt'] = Math.round(time)
  if strategy?
    val["Search strategy"] = strategy
  val['Encoding / Engine'] = encoding + ' / ' + engine

  self.postMessage(val)