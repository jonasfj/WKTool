@config =   # Global vs Local, Task Graphs (Scaling Problem)
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
