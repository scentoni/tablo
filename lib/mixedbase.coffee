class @MixedBase
  # Like APL's decode operator
  # decode([6, 5, 0], [0, 20, 12]) is 1500
  @decode = (c, b, wraparound = true) ->
    i = 0
    for bk, k in b
      [q, r] = @divmodfloor(c[k], bk)
      return null unless q is 0 or wraparound
      i = i * bk + r
    i

  # Like APL's encode operator
  # encode(1500, [0, 20, 12]) is [6, 5, 0]
  @encode = (i, b, wraparound = true) ->
    [q, i] = @divmodfloor(i, @product(b))
    return null unless q is 0 or wraparound
    c = []
    for bk, k in b by -1
      [i, c[k]] = @divmodfloor i, bk
    c

  # Integer quotient and remainder
  @divmodfloor = (dend, dsor) ->
    if dsor is 0
      [0, dend]
    else
      [Math.floor(dend/dsor), (dend % dsor + dsor) % dsor] # floor
      # [Math.floor(a/b), a%b] # trunc

  @plus = (a, b) -> a + b
  @times = (a, b) -> a*b
  @sum = (v) -> _.reduce(v, @plus)
  @product = (v) -> _.reduce(v, @times)
  @sumList = (v) -> @reduceList(v, @plus)
  @productList = (v) -> @reduceList(v, @times)

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
