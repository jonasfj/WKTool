
# Comparison of local and global MMG algorithm

@config = {  # Global vs Local (Scaling Problem)
  ##
  "LeaderElectionN_ScalingProblem": {
    model:  "Leader Election with N Processes"
    pindex: 0
    params: [
      ([i, 200] for i in [7..13])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['min-max']
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
      {
        qindex:   6
        name:     "\\texit{EF}_{>= 10} \\texit{AG} \\textit{leader}"
        sat:      true
      },
    ]
  }
  # positive formulas
  # Do consider using AG ((!send0) || EF deliver0)
  "AlternatingBitProtocol1DeliveryBound10_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 10] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['min-max']
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
    encodings:  ['min-max']
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
    encodings:  ['min-max']
    properties: [
      {
        qindex:   3
        name:     "EF delivered == 1"
        sat:      true
      }
    ]
  }
  # Negative formulas
  "AlternatingBitProtocolSaftyBound10_ScalingProblem": {
    model:  "k-Buffered Alternating Bit Protocol"
    pindex: 0
    params: [
      ([i, 1, 10] for i in [1..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['min-max']
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
    encodings:  ['min-max']
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
    encodings:  ['min-max']
    properties: [
      {
        qindex:   5
        name:     "EF (send0 && deliver1) || (send1 && deliver0)"
        sat:      false
      }
    ]
  }
}