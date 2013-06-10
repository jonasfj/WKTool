
# Experiment for comparison of direct, symbolic and min-max when bound is scaled

@config =
  "LeaderElection8_ScalingBound": {
    model:  "Leader Election with N Processes"
    pindex: 1
    params: [
      ([8, i] for i in [200..1000] by 200)...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['naive', 'symbolic', 'min-max']
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
    encodings:  ['naive', 'symbolic', 'min-max']
    properties: [
      {
        qindex:   2
        name:     "\\EUntil{\\True}{n}{\\textit{delivered} = 1}"
        sat:      true
      }
      {
        qindex:   4
        name:     "\\EUntil{\\True}{n}{(s_0 \\wedge d_1) \\vee (s_1 \\wedge d_0)}"
        sat:      false
      }
    ]
  }