
@ScalableModels = {}
@ScalableModelParameter = {}

#### Leader Election Example
ScalableModels["Leader Election with N Processes"] = 
  defaults:   [3]
  parameters: ["Number of processes in the ring, which must elect a leader."]
  factory:    (n) ->
    message = (reciever, rank) -> "m#{reciever}r#{rank}"
    # Create the ring process
    messages = []
    for i in [1..n]
      for j in [1..n]
        messages.push message(i, j)
    messages = messages.join(', ')
    ring  = "Ring := (" + ("P#{i}" for i in [1..n]).join(' | ') + ")\n"
    ring += "        \\ {#{messages}};\n"
    
    # Make various processes
    procs = []
    for i in [1..n]
      next = if i + 1 > n then 1 else i + 1
      choices = ["<#{message(next, i)}!,1>.P#{i}"]
      for r in [1..n]
        msg = message(i, r)
        if r < i
          # Received smaller rank
          choices.push "<#{msg}>.P#{i}"
        else if i == r
          # Received same rank
          # Pi is now the leader
          choices.push "<#{msg}>.leader:0"
        else # if r > i
          # Received higher rank
          choices.push "<#{msg}>.P#{i}_#{r}"
      procs.push "P#{i} := #{choices.join(' + ')};\n"
      # Auxiliary processes
      for j in [i+1...n+1]
        choices = ["<#{message(next, j)}!,1>.P#{i}_#{j}", "<#{message(i, i)}>.leader:0"]
        for r in [1..n]
          msg = message(i, r)
          if i == r
            continue
          if r <= j
            # Received smaller rank, than equal rank
            # Thus, we keep the state
            choices.push "<#{msg}>.P#{i}_#{j}"
          else # if r > j
            # Received higher rank
            choices.push "<#{msg}>.P#{i}_#{r}"
        procs.push "P#{i}_#{j} := #{choices.join(' + ')};\n"
      procs.push '\n'
    procs.push ring
    # Description of the model
    desc = [
      "#### Ring-based Leader Election Protocol"
      "# This example has processes P1 to P#{n}, each process have several states denoted by process"
      "# name underscore largest rank received. E.g. P1_2 is P1 in a state where it has received a"
      "# message with rank 2."
      "# Messages are on the form 'm:receiver r:rank'"
    ].join('\n')
    return {
      name: "Leader Election with #{n} Processes"
      model:
        language:       'WCCS'
        definition:     desc + "\n" + procs.join('')
      properties: [
        {
          state:    "Ring"
          formula:  "#It is possible to elect a leader\nEF leader"
        },
        {
          state:    "Ring"
          formula:  "#A leader can be elected within n*n messages\nEF[<=#{n*n}] leader"
        },
        {
          state:    "Ring"
          formula:  "#Two leaders cannot be elected simultaneously\nEF leader > 1"
        }
      ]
    }


#### Semaphore Example
ScalableModels["k-Semaphore with N processes"] = 
  defaults:   [3, 5]
  parameters: [
                "Initial value of semaphore (ie. maximum number of processes in the critical section)"
                "Number of parallel processes"
              ]
  factory:    (k, N) ->
    name:   "#{k}-Semaphore Example with #{N} Threads"
    model:
      language:   'WCCS'
      definition:
        [
          "#### Semaphore Example"
          "# In this is example a semaphore with an initial value of #{k} ensures that at most #{k}"
          "# of #{N} parallel threads enter the critical section at the same time."
          "# The semaphore has #{k} cells, where each cell can be locked and unlocked."
          "# The number of cells limits the access to the critical section."
          ""
          "# System consists of a semaphore and a collection of threads"
          "System     := (Semaphore | Threads) \\ {lock, unlock};"
          ""
          "# A thread enters its critical section after locking, and exits by unlocking"
          "Thread     := <lock!>.critical_section:<unlock!>.Thread;"
          ""
          "# A semaphore cell (used for building a semaphore)"
          "Cell       := <lock>.<unlock>.Cell;"
          ""
          "# A semaphore with value counted by number of cells"
          "Semaphore  := #{('Cell' for i in [0...k]).join(' | ')};"
          ""
          "# Threads is set of parallel threads"
          "Threads    := #{('Thread' for i in [0...N]).join(' | ')};"
        ].join('\n')
    properties: [
      {
        state:    "System"
        formula:  "# There cannot be more than #{k} threads in the critical section\nEF critical_section > #{k}"
      },
      {
        state:    "System"
        formula:  "# There can be #{k} threads in the critical section\nEF critical_section == #{k}"
      }
    ]
