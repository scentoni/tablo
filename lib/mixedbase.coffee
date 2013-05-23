class @MixedBase
  # Like APL's decode operator
  # decode([6, 5, 0], [0, 20, 12]) is 1500
  @decode = (c, b, wraparound = false) ->
    i = 0
    for k in [0...b.length]
      return null unless 0 <= c[k] < b[k] or wraparound
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
  @encode = (i, b, wraparound = false) ->
    return null unless 0 <= i < @product(b) or wraparound
    c = []
    for bk, k in b by -1
      [i, c[k]] = @divmodfloor i, b[k]
    c

  @plus = (a, b) -> a + b
  @times = (a, b) -> a*b
  @sum = (v, ...args) -> _.reduce(v, @plus, args)
  @product = (v, ...args) -> _.reduce(v, @times, args)
  @sumList = (v, ...args) -> @reduceList(v, @plus, args)
  @productList = (v, ...args) -> @reduceList(v, @times, args)

  @reduceList = (array, f, initial) ->
    if 2 < arguments.length
      last = initial
      i = 0
    else
      last = array[0]
      i = 1
    acc = [last]
    while i < array.length
      last = f last, array[i], i, array
      acc.push last
      ++i
    acc
