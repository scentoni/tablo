@toFixed = (x, prec = 0) ->
  power = Math.pow 10, prec
  (Math.round(x*power) / power).toFixed(prec)

class @ContingencyTable
  @updateMargins = (t) ->
    t.dim = (c.length for c, i in t.categories)
    t.dimarg = (i + 1 for i in t.dim)
    t.datmarg = (0 for i in [0...MixedBase.product(t.dimarg)])
    for v, i in t.data
      v = parseFloat v ? 0
      rc = MixedBase.encode i, t.dim
      for s in [0...(1 << t.dim.length)] # 1 << n = 2^n
        j = MixedBase.decode (@bitpick s, rc, t.dim), t.dimarg
        t.datmarg[j] += v
    t

# return an array whose kth element is
# fs[k] if the kth bit of s is 0 or
# ts[k] if the kth bit of s is 1
  @bitpick = (s, fs, ts) ->
    [fs[i], ts[i]][1 & (s >> i)] for tsi, i in ts

  square = (x) ->
    x*x

# http://www.vassarstats.net/abc.html
# http://ieeexplore.ieee.org/xpl/login.jsp?tp=&arnumber=6468603
# http://udel.edu/~mcdonald/statsmall.html
# http://datavis.ca/online/mosaics/dataformat.html
# http://userwww.sfsu.edu/efc/classes/biol710/loglinear/Log%20Linear%20Models.htm
  @updateStatistics = (t) ->
    @updateMargins t
    t.df = MixedBase.product(t.dim) - MixedBase.sum(t.dim) + t.dim.length - 1
    t.chi2 = 0
    t.gstat = 0
    t.mi = (0 for e in t.data)
    itotal = 1.0 / Math.max(1, _.last t.datmarg)
    t.expected = (Math.pow(itotal, t.dim.length - 1) for e in t.data)
    for di, i in t.data
      rc = MixedBase.encode i, t.dim
      for s, j in t.dim
        ind = MixedBase.decode (@bitpick 1 << j, t.dim, rc), t.dimarg
        t.expected[i] *= t.datmarg[ind]
      if t.expected[i]
        t.chi2 += square(t.data[i] - t.expected[i])/t.expected[i]
        ll = t.data[i]*Math.log(t.data[i] / t.expected[i])
        t.gstat += ll
        t.mi[i] = ll * itotal
    t.gstat *= 2
    t.pvalue = Chisq.pvalue t.df, t.chi2
    t

  @updateAll = (t) ->
    @updateStatistics t

  @permuteCategories = (t, parray) ->
    # structure of p is something like
    # parray = [ [1, 0], [0, 1, 3, 4]] # rows are exchanged, column 2 is removed
    newdim = (c.length for c in parray)
    newdata = (0 for i in [0...MixedBase.product(newdim)])
    for d, i in newdata
      rc = MixedBase.encode i, newdim
      oldrc = (parray[j][c] for c, j in rc)
      j = MixedBase.decode oldrc, t.dim
      newdata[i] = t.data[j] ? 0
    newcategories = (((t.categories[i][c] ? '') for c, j in p) for p, i in parray)
    t.data = newdata
    t.dim = newdim
    t.categories = newcategories
    t

  @identityCategoryPermutation = (t) ->
    [0...d] for d in t.dim

  @permuteVariables = (t, parray) ->
    newdim = (t.dim[c] for c in parray)
    newvariables = (t.variables[c] ? '' for c in parray)
    newcategories = (t.categories[c] ? '' for c in parray)
    newdata = (0 for i in [0...MixedBase.product(newdim)])
    for d, i in t.data
      rc = MixedBase.encode i, t.dim
      newrc = (rc[c] for c in parray)
      j = MixedBase.decode newrc, newdim
      newdata[j] += t.data[i] ? 0
    t.data = newdata
    t.dim = newdim
    t.categories = newcategories
    t.variables = newvariables
    t

  @tocsv = (t, fs=',') ->
    s = t.title + '\n'
    s += t.variables.join(fs) + fs + 'count\n'
    for d, i in t.data
      rc = MixedBase.encode i, t.dim
      s += (t.categories[j][c] for c, j in rc).join(fs) + fs + d + '\n'
    s
