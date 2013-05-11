# example data taken from
# http://www.stat.cmu.edu/~gklein/discrete/OpeningExamples-2011.pdf
@resetDatabase = ->
  console.log "Resetting database!"
  if Tables?.find()
    for t in Tables.find().fetch()
      Tables.remove t._id
  sampleTables = [
    title: "political party affiliation vs. gender"
    variables: ["gender", "party"]
    categories: [["female", "male"], ["Dem", "ind", "Rep"]]
    data: [762, 484, 327, 239, 468, 477]
  ,
    title: "cold French skiers"
    variables: ["intervention", "outcome"]
    categories: [["placebo", "treatment"], ["cold", "no cold"]]
    data: [31, 109, 17, 122]
  ]
  for t in sampleTables
    ContingencyTable.updateMargins t
    Meteor.call 'createTable', t

class @ContingencyTable
  @updateMargins = (t) ->
    t.dimensions = new Array t.variables.length
    for c, i in t.categories
      t.dimensions[i] = c.length
    t.grandtotal = 0
    t.margincol = (0 for e in [0...t.dimensions[0]])
    t.marginrow = (0 for e in [0...t.dimensions[1]])
    for r in [0...t.dimensions[0]]
      for c in [0...t.dimensions[1]]
        i = MixedBase.decode [r,c], t.dimensions
        x = t.data[i]
        x = parseFloat x ? 0
        t.data[i] = x
        t.grandtotal += x
        t.marginrow[c] += x
        t.margincol[r] += x
    t

  square = (x) ->
    x*x

  @updateStatistics = (t) ->
    @updateMargins t
    t.df = (t.dimensions[0] - 1)*(t.dimensions[1] - 1)
    t.expected = (0 for e in t.data)
    t.chisq = 0
    itotal = 1.0 / Math.max(1, t.grandtotal)
    for di, i in t.data
      [r, c] = MixedBase.encode i, t.dimensions
      t.expected[i] = t.margincol[r] * t.marginrow[c] * itotal
      t.chisq += square(t.data[i] - t.expected[i])/t.expected[i]
    t.pvalue = Chisq.pvalue t.df, t.chisq

  @updateAll = (t) ->
    @updateStatistics t

@toFixed = (x, prec = 0) ->
  power = Math.pow 10, prec
  (Math.round(x*power) / power).toFixed(prec)