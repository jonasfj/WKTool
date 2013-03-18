#! /usr/bin/env coffee

os            = require 'os'
fs            = require 'fs'
{spawn}       = require 'child_process'
path          = require 'path'

global.fetchTaskGraph = (file) ->
  filename = path.join(__dirname, '../', file)
  return fs.readFileSync(filename, 'utf8')

{ScalableModels: global.ScalableModels} = require './ScalableModels'

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
NOTE: ABP is identical for global/local, not easy to explain
###




configurations = {    # Naive vs Symbolic (Scaling Bound)
  ###
  "LeaderElection8_ScalingBound": {
    model:  "Leader Election with N Processes"
    pindex: 1
    params: [
      ([8, i] for i in [200..1000] by 200)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   3
        name:     "\\EUntil{\\True}{n}{\\textit{leader}}"
        sat:      true
      },
      {
        qindex:   4
        name:     "\\EUntil{\\True}{n}{\\textit{leader} > 1}"
        sat:      false
      }
    ]
  }

  "AlternatingBitProtocol41_ScalingBound": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 2
    params: [
      ([4, 1, i] for i in [100..500] by 100)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   2
        name:     "\\EUntil{\\True}{n}{\\textit{delivered} = 1}"
        sat:      true
      }
      {
        qindex:   3
        name:     "\\EUntil{\\True}{n}{(s_0 \\wedge d_1) \\vee (s_1 \\wedge d_0)}"
        sat:      false
      }
    ]
  }
  ##
  }



  configurations = {  # Global vs Local (Scaling Problem)
  ##
  "LeaderElectionN_ScalingProblem": {
    model:  "Leader Election with N Processes"
    pindex: 0
    params: [
      ([i, 200] for i in [7..13])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   3
        name:     "\\EUntil{\\True}{200}{\\textit{leader}}"
        sat:      true
      },
      {
        qindex:   4
        name:     "\\EUntil{\\True}{200}{\\textit{leader} > 1}"
        sat:      false
      },
    ]
  }
  ##
}


# Models: 0055, 0125, 0155

configurations = {  # Global vs Local, Task Graphs (Scaling Problem)
  ###

  ###
  "TaskGraph55": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([55, i] for i in [2..9])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF (tn-2_ready && AF[<= 500] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF (tn-2_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  ###
  
  ###
  "TaskGraph125": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([125, i] for i in [2..9])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF (t1_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF (t1_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  
    "TaskGraph155": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([155, i] for i in [2..9])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF (t1_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF (t1_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  
  ###
  
  


  "TaskGraph0": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([0, i] for i in [2..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= 90](t_n-2_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF[<= 10](t_n-2_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  "TaskGraph1": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([1, i] for i in [2..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= 90](t_n-2_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF[<= 10](t_n-2_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }

  "TaskGraph2": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([2, i] for i in [2..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= 90](t_n-2_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF[<= 10](t_n-2_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  
  "TaskGraph155": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([155, i] for i in [2..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= 90](t_n-2_ready && AF[<= 80] done == N+2)"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF[<= 10](t_n-2_ready && AF[<5] done == N+2)"
        sat:      false
      }
    ]
  }
  
  ### # positive formulas
  "AlternatingBitProtocol1DeliveryBound10_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 10] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   2
        name:     "EF[<= k * 1] delivered == 1"
        sat:      true
      }
    ]
  }
  "AlternatingBitProtocol1DeliveryBound20_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 20] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   2
        name:     "EF[<= k * 1] delivered == 1"
        sat:      true
      }
    ]
  }
  "AlternatingBitProtocol1DeliveryUnbounded_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 500] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   3
        name:     "EF delivered == 1"
        sat:      true
      }
    ]
  }
  ###
  
  ###
  "AlternatingBitProtocolSaftyBound10_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 10] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   4
        name:     "EF[<= 10] (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }
  "AlternatingBitProtocolSaftyBound20_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 20] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   4
        name:     "EF[<= 20] (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }
  "AlternatingBitProtocolSaftyUnbounded_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 500] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   5
        name:     "EF (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }
  
  ###
}




### Some vi havde det sjovt med
configurations = {

  "Leader Election with 8 Processes (Scaling Bound)": {
    model:  "Leader Election with N Processes"
    pindex: 1
    params: [
      ([8, i] for i in [20..300] by 20)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   3
        name:     "EF[<= n] leader"
        sat:      true
      },
      {
        qindex:   4
        name:     "EF[<= n] leader > 1"
        sat:      false
      },
      {
        qindex:   5
        name:     "AF[<= n] leader"
        sat:      false
      }
    ]
  }

  "LOCAL-ONLY: Leader Election with 8 Processes (Scaling Bound)": {
    model:  "Leader Election with N Processes"
    pindex: 1
    params: [
      ([8, i] for i in [10000..80000] by 10000)...
    ]
    engines:    ['local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   3
        name:     "EF[<= n] leader "
        sat:      true
      },
      {
        qindex:   5
        name:     "AF[<= n] leader"
        sat:      false
      }
    ]
  }

  "4-Buffered Alternating Bit Protocol with 1 Delivery (Scaling Bound)": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 2
    params: [
      ([4, 1, i] for i in [100..1000] by 100)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   2
        name:     "EF[<= n] delivered == 1"
        sat:      true
      }
    ]
  }
  
  "LOCAL-ONLY: 4-Buffered Alternating Bit Protocol with 1 Delivery (Scaling Bound)": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 2
    params: [
      ([4, 1, i] for i in [1000..20000] by 1000)...
    ]
    engines:    ['local-dfs']
    encodings:  ['naive', 'symbolic']
    properties: [
      {
        qindex:   2
        name:     "EF[<= n] delivered == 1"
        sat:      true
      }
    ]
  }

  "n-Buffered Alternating Bit Protocol with 4 Deliveries (Scaling Problem)": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 4, 20] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= k * 4] delivered == 4"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }

  "n-Buffered Alternating Bit Protocol with 1 Delivery (Scaling Problem)": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 20] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   0
        name:     "EF[<= k * 1] delivered == 1"
        sat:      true
      },
      {
        qindex:   1
        name:     "EF (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }
  
  "Leader Election with n Processes (Scaling Problem)": {
    model:  "Leader Election with N Processes"
    pindex: 0
    params: [
      ([i, 200] for i in [3..16])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['symbolic']
    properties: [
      {
        qindex:   3
        name:     "EF[<= 200] leader"
        sat:      true
      },
      {
        qindex:   4
        name:     "EF[<= 200] leader > 1"
        sat:      false
      },
      {
        qindex:   5
        name:     "AF[<= 200] leader"
        sat:      false
      }
    ]
  }
}
###

# Memory Size
memlimit    = 1000  # MiB

timeout     = 10 * 60000 #ms

engines     = ['global', 'local-dfs', 'local-bfs']
encodings   = ['naive', 'symbolic']

# Temporary file
tmpFile = path.join os.tmpDir(), "WKTool-benchmark-input-#{process.pid}.wks"

# WKTool js file
WKTool = path.join(__dirname, 'WKTool.js')

# Run query at qindex from model with engine and encoding
run = (model, qindex, engine, encoding, callback) ->
  console.error("Running: " + model.name + " with " + encoding + "/" + engine + " qindex: " + qindex)
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
      if retval.indexOf("process out of memory") != -1
        out =
          failed:   "OOM"
          message:  retval
        console.error("Out-of-memory")
      else if timedOut
        out = 
          failed:   "Timeout"
          message:  retval
        console.error("Timeout")
      else
        console.error("Unknown death")
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


do ->
  results = {}
  for table, conf of configurations
    results[table] = props = []
    for prop in conf.properties
      m = ScalableModels[conf.model].factory(conf.params[0]...)
      props.push pVal =
        pindex:   conf.pindex
        formula:  prop.name
        sat:      prop.sat
        state:    m.properties[prop.qindex].state
        instances: []
      for param in conf.params
        pVal.instances.push inst = 
          param:    param
        model = ScalableModels[conf.model].factory(param...)
        for encoding in conf.encodings
          for engine in conf.engines
            key = encoding + "/" + engine
            job_run(model, prop.qindex, engine, encoding, inst, key)
  
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
