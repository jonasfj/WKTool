@config =   # Global vs Local MMG, Task Graphs (Scaling Problem for full WCTL)
  "TaskGraph0": {
    model:  "Standard Task Graph"
    pindex: 1
    params: [
      ([0, i] for i in [2..10])...
    ]
    engines:    ['global', 'local-dfs']
    encodings:  ['min-max']
    properties: [
      {
        qindex:   5
        name:     "EF[<= 10](t_n-2_ready && !AF[<= 5] done == N+2)"
        sat:      true
      },
      {
        qindex:   6
        name:     "AF[<= 10](t_n-2_ready && !EF[<= 5] done == N+2)"
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
    encodings:  ['min-max']
    properties: [
      {
        qindex:   5
        name:     "EF[<= 10](t_n-2_ready && !AF[<= 5] done == N+2)"
        sat:      true
      },
      {
        qindex:   6
        name:     "AF[<= 10](t_n-2_ready && !EF[<= 5] done == N+2)"
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
    encodings:  ['min-max']
    properties: [
      {
        qindex:   5
        name:     "EF[<= 10](t_n-2_ready && !AF[<= 5] done == N+2)"
        sat:      true
      },
      {
        qindex:   6
        name:     "AF[<= 10](t_n-2_ready && !EF[<= 5] done == N+2)"
        sat:      false
      }
    ]
  }
