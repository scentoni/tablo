class @MixedBase
  # Like APL's decode operator
  # decode([6, 5, 0], [0, 20, 12]) is 1500
  @decode = (c, b) ->
    i = 0
    for k in [0...b.length]
      i = i * b[k] + c[k]
    i

  # Integer quotient and remainder
  @divmodfloor = (dend, dsor) ->
    if dsor is 0
      [0, dend]
    else
      [Math.floor(dend/dsor), (dend % dsor + dsor) % dsor] # floor
      # [Math.floor(a/b), a%b] # trunc

  # Like APL's encode operator
  # encode(1500, [0, 20, 12]) is [6, 5, 0]
  @encode = (i, b) ->
    c = []
    for bk, k in b by -1
      [i, c[k]] = @divmodfloor i, b[k]
    c
