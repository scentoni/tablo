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

  @rotateArray = (arr, count) ->
    if count
      arr = arr.slice(0)
      [_, count] = @divmodfloor count, arr.length
      arr.splice(0, 0, arr.splice(arr.length - count, count)...)
      arr

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

  @decodeFactorial = (v) ->
    MixedBase.decode v, [v.length..1]

  @encodeFactorial = (n) ->
    f = 1
    p = 1
    b = [1]
    while p <= n
      f += 1
      p *= f
      b.push f
    b.reverse()
    MixedBase.encode n, b

  @parityPermutation = (p, n=p.length) ->
    parity = 0
    for pi, i in p
      for j in [i + 1...n]
        parity += 1 if pi > p[j]
    parity % 2

  swap = (p, a, b) ->
    [p[a], p[b]] = [p[b], p[a]]
    p

# https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm
  @nextPermutation = (p) ->
    x = []
    for pi, i in p
      x[pi] = i
    y = []
    for xi, i in x
      if 0 is MixedBase.parityPermutation(_.filter(p, (x)->x < i))
        y[i] = xi - 1
      else
        y[i] = xi + 1
    for yi, i in y by -1
      if p[yi] < i
        swap p, x[i], y[i]
        return p
    p.sort()
