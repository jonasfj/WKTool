#! /usr/bin/env coffee

os            = require 'os'
fs            = require 'fs'
{spawn}       = require 'child_process'
path          = require 'path'

{ScalableModels: global.ScalableModels} = require '../bin/scripts/ScalableModels'

# Configuration
###
Consider only: local-dfs
Remember: positive/negative instances

Naive vs Symbolic, Scale bound
+ Leader Election with P=6        EF[<=#{n*n}] leader
- Leader Election with P=6        AF[<=n*n] 
+ Alternating Bit Protocol B=4    EF[<= #{k * n}] delivered == #{n}

Local vs Global, Scale problem size
- Alternating Bit Protocol D=1    EF (send0 && deliver1) || (send1 && deliver0)
+ Alternating Bit Protocol D=4    EF[<= #{k * n + 500}] delivered == #{n}
###

configurations = {
  "Leader Election with 8 Processes (Scaling Bound)": {
    model:  "Leader Election with N Processes"
    params: [
      ([8, i] for i in [20..300] by 20)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: {
      3:  "EF[<= n] leader                                  SAT"
      4:  "EF[<= n] leader > 1                              UNSAT"
      5:  "AF[<= n] leader                                  UNSAT"
    }
  }

  "LOCAL-ONLY: Leader Election with 8 Processes (Scaling Bound)": {
    model:  "Leader Election with N Processes"
    params: [
      ([8, i] for i in [10000..80000] by 10000)...
    ]
    engines:    ['local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: {
      3:  "EF[<= n] leader                                  SAT"
      5:  "AF[<= n] leader                                  UNSAT"
    }
  }

  "4-Buffered Alternating Bit Protocol with 1 Delivery (Scaling Bound)": {
    model:  "k-Buffered Alternating Bit Protocol"
    params: [
      ([4, 1, i] for i in [100..1000] by 100)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties:
      2:  "EF[<= n] delivered == 1                          SAT"
  }
  
  "LOCAL-ONLY: 4-Buffered Alternating Bit Protocol with 1 Delivery (Scaling Bound)": {
    model:  "k-Buffered Alternating Bit Protocol"
    params: [
      ([4, 1, i] for i in [1000..20000] by 1000)...
    ]
    engines:    ['local-dfs']
    encodings:  ['naive', 'symbolic']
    properties:
      2:  "EF[<= n] delivered == 1                          SAT"
  }

  "n-Buffered Alternating Bit Protocol with 4 Deliveries (Scaling Problem)": {
    model:  "k-Buffered Alternating Bit Protocol"
    params: [
      ([i, 4, 20] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties:
      0: "EF[<= k * 4] delivered == 4                       SAT"
      1: "EF (send0 && deliver1) || (send1 && deliver0)     UNSAT"
  }
  
  "Leader Election with n Processes (Scaling Problem)": {
    model:  "Leader Election with N Processes"
    params: [
      ([i, 200] for i in [3..16])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: {
      3:  "EF[<= 200] leader                                  SAT"
      4:  "EF[<= 200] leader > 1                              UNSAT"
      5:  "AF[<= 200] leader                                  UNSAT"
    }
  }
}


###
configurations = {
  "Leader Election 1 - 4": {
    model:  "Leader Election with N Processes"
    params: [
      ([i] for i in [1..4])...
    ]
    engines:    ['global', 'local-dfs', 'local-bfs']
    encodings:  ['naive', 'symbolic']
    properties: {
      0:  "EF critical_section > n"
      1:  "EF critical_section == n"
    }
  },
  "Leader Election 4 - 6": {
    model:  "Leader Election with N Processes"
    params: [
      ([i] for i in [4..6])...
    ]
    engines:    ['global', 'local-dfs', 'local-bfs']
    encodings:  ['naive', 'symbolic']
    properties:
      0:  "EF critical_section > n"
  }
}
###

###
models = {
  "Leader Election with N Processes":     [([i] for i in [1..12])...]
  "k-Buffered Alternating Bit Protocol":  [
    ([i, 1] for i in [1..7])...,
    ([i, 2] for i in [1..7])...,
    ([i, 3] for i in [1..7])...,
    ([i, 4] for i in [1..7])...
  ]
}
###

# Memory Size
memlimit    = 1000  # MiB

timeout     = 60000 #ms

engines     = ['global', 'local-dfs', 'local-bfs']
encodings   = ['naive', 'symbolic']

# Temporary file
tmpFile = path.join os.tmpDir(), "WKTool-benchmark-input-#{process.pid}.wks"

# WKTool js file
WKTool = path.join(__dirname, 'WKTool.js')

# Run query at qindex from model with engine and encoding
run = (model, qindex, engine, encoding, callback) ->
  fs.writeFileSync(tmpFile, JSON.stringify(model))
  retval = ""
  proc = spawn 'node', ['--max-old-space-size=' + memlimit, WKTool, '--' + engine, '--' + encoding, tmpFile, "" + qindex]
  proc.stdout.on 'data', (data) -> retval += data
  proc.stderr.on 'data', (data) -> retval += data
  timedOut = false
  myTimeout = setTimeout (->
    timedOut = true
    proc.kill()
  ), timeout
  proc.on 'exit', (status) ->
    clearTimeout myTimeout
    try
      out = JSON.parse(retval)
    catch err
      if "process out of memory" in retval
        out =
          failed:   "OOM"
          message:  retval
      else if timedOut
        out = 
          failed:   "Timeout"
          message:  retval
      else
        out = 
          failed:   "Unknown"
          message:  retval
    callback(status is 0, out)

# Things to execute
jobs = []

job_run = (model, qindex, engine, encoding, instResult, key) ->
  cb = (success, result) ->
    instResult[key] = {success, result}
    nextJob()
  jobs.push ->
    run(model, qindex, engine, encoding, cb)

instance_jobs = (model, qindex, instResult) ->
  for encoding in encodings
    for engine in engines
      key = encoding + "/" + engine
      job_run(model, qindex, engine, encoding, instResult, key)

model_jobs = (model, qindex, params, instances) ->
  for param in params
    m = ScalableModels[model].factory(param...)
    inst =
      model:    model
      param:    param
      name:     m.name
    instances.push inst
    instance_jobs(m, qindex, inst)

model_prop_jobs = (model, params, results) ->
  props = []
  results[model] = props
  # Just to count number of properties
  m = ScalableModels[model].factory(params[0]...)
  for prop, i in m.properties
    propResult =
      state:      prop.state
      formula:    prop.formula
      instances:  []
    props.push propResult
    model_jobs(model, i, params, propResult.instances)

do ->
  #results = {}
  #for model, params of models
  #  model_prop_jobs(model, params, results)
  
  results = {}
  for table, conf of configurations
    results[table] = props = []
    for qindex, prop of conf.properties
      m = ScalableModels[conf.model].factory(conf.params[0]...)
      props.push pVal = 
        formula:  prop
        state:    m.properties[qindex].state
        instances: []
      for param in conf.params
        pVal.instances.push inst = 
          param:    param
        model = ScalableModels[conf.model].factory(param...)
        for encoding in conf.encodings
          for engine in conf.engines
            key = encoding + "/" + engine
            job_run(model, qindex, engine, encoding, inst, key)
  
  # Last job, print all output
  jobs.push ->
    console.log JSON.stringify(results)

nJobs = jobs.length

nextJob = ->
  if jobs.length > 0
    console.error "Starting job #{nJobs - jobs.length + 1} of #{nJobs}"
    jobs.shift()()
  else
    console.error "Finished!"

nextJob()