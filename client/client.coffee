Accounts.ui.config
  passwordSignupFields: "USERNAME_AND_EMAIL"

Meteor.subscribe "tables"

Meteor.subscribe "directory"

blankTable =
  title: ' '
  description: ' '
  variables: ['', '']
  categories: [['', ''], ['', '']]
  data: [0, 0, 0, 0]
  publicq: true

Meteor.startup ->
  console.log "Hello!"
  Session.set 'showViewTable', false
  Session.set 'showEditTable', false

###########################################################
# Template.page
Template.page.showViewTable = ->
  Session.get 'showViewTable'

Template.page.showEditTable = ->
  Session.get 'showEditTable'

Template.page.events
  'click #reset': ->
    Session.set 'showViewTable', false
    Session.set 'showEditTable', false
    Session.set 'table', {}
    Meteor.call 'resetDatabase'

###########################################################
# Template.sidebar

Template.userList.userList = ->
  Meteor.users.find {}

Template.userList.displayUsername = ->
  this.username

Template.userList.displayUserID = ->
  this._id

Template.tableList.tableList = ->
  Tables.find {}

Template.tableList.lookupTableID = ->
  lookupTableID this

Template.tableList.displayTitle = ->
  this.title

Template.tableList.displayOwner = ->
  if this.owner
    (Meteor.users.findOne this.owner).username
  else
    ''

Template.tableList.events
  "click td": (event, template) ->
    t = Tables.findOne this._id
    console.log "loading table #{this._id}"
    ContingencyTable.updateAll t
    Session.set 'table', t
    Session.set 'showViewTable', true
    Session.set 'showEditTable', false
    console.log t

  "click #addtable": (event, template) ->
    console.log "Adding table"
    ContingencyTable.updateMargins blankTable
    Session.set 'table', blankTable
    Session.set 'showViewTable', false
    Session.set 'showEditTable', true

###########################################################
# Template.main
Template.main.showViewTable = ->
  Session.get 'showViewTable'

Template.main.showEditTable = ->
  Session.get 'showEditTable'

###########################################################
# Template.viewTable

# split |-
layoutxy = (t) ->
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i]} for e, i in t.data)
  x = 0
  for c in [0...t.dim[1]]
    y = 0
    marg = fmarg[MixedBase.decode [t.dim[0], c], t.dimarg]
    for r in [0...t.dim[0]]
      i = MixedBase.decode [r, c], t.dim
      data[i].w = marg
      data[i].h = data[i].a / data[i].w
      data[i].x = x
      data[i].y = y
      data[i].name = "#{t.categories[0][r]}|#{t.categories[1][c]}"
      y += data[i].h
    x += data[i].w
  data

# split -|
layoutyx = (t) ->
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i]} for e, i in t.data)
  y = 0
  for r in [0...t.dim[0]]
    x = 0
    marg = fmarg[MixedBase.decode [r, t.dim[1]], t.dimarg]
    for c in [0...t.dim[1]]
      i = MixedBase.decode [r, c], t.dim
      data[i].h = marg
      data[i].w = data[i].a / data[i].h
      data[i].x = x
      data[i].y = y
      x += data[i].w
    y += data[i].h
  data


# split -|-
# t.variables is ["sex", "eye", "hair"]
# split x:hair, y:eye, x:sex
layoutxyx = (t) ->
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i]} for e, i in t.data)
  x = [0, 0]
  for va in [0...t.dim[2]]
    # console.log "#{t.variables[2]}=#{t.categories[2][va]}"
    # j = MixedBase.decode (MixedBase.bitpick s, rc, t.dim), t.dimarg
    w = fmarg[MixedBase.decode [-1, -1, va], t.dimarg]
    y = [0]
    for vb in [0...t.dim[1]]
      h = fmarg[MixedBase.decode [-1, vb, va], t.dimarg]/w
      x[1] = 0
      for vc in [0...t.dim[0]]
        i = MixedBase.decode [vc, vb, va], t.dim
        data[i].h = h
        data[i].w = data[i].a / h
        data[i].x = MixedBase.sum x
        data[i].y = MixedBase.sum y
        data[i].name = "#{t.categories[0][vc]}#{t.categories[1][vb]}#{t.categories[2][va]}"
        # data[i].name = "#{vc}|#{vb}|#{va}"
        x[1] += data[i].w
      y[0] += h
    x[0] += w
  data

Template.mosaic.rendered = () ->
  self = this
  self.node = self.find "svg"

  return if self.handle
  self.handle = Deps.autorun () ->
    t = Session.get 'table'
    ContingencyTable.updateAll t
    if t.dim.length is 2
      data = layoutxy t
    else if t.dim.length is 3
      data = layoutxyx t

    Session.set('data', data)
    console.log data
    # mcol = (fmarg[MixedBase.decode [r, t.dim[1]], t.dimarg] for r in [0...t.dim[0]])
    # console.log mcol
    # mrow = (fmarg[MixedBase.decode [t.dim[0], c], t.dimarg] for c in [0...t.dim[1]])
    # console.log mrow

    # example specification for splitting:
    # [ [1,0,2], # order of splitting
    #   [4,0,1], # x axis
    #   [3,5],   # y axis
    #   [6,7,2]] # z axis

    # vsplit = 1
    # for di, i in t.dim
    #   console.log "split dimension #{i} into #{di} stripes #{['|', '-'][vsplit]}"
    #   for j in [0...di]
    #     console.log "stripe #{j} "
    #   vsplit = 1 - vsplit

    height = width = 300
    colorscale = d3.scale.linear().domain([-1, 0, 1]).range(["red", "white", "blue"])
    sigmoid = (x) -> x / (1 + Math.abs(x))

    updateRectangles = (group) ->
      group.attr("x", (datum) ->
        datum.x * width
      ).attr("y", (datum) ->
        datum.y * height
      ).attr("width", (datum) ->
        datum.w * width
      ).attr("height", (datum) ->
        datum.h * height
      ).attr("foo", (datum) ->
        colorscale(datum.mi)
      ).style("fill", (datum) ->
        colorscale(sigmoid(10*datum.mi))
      ).style("stroke", "black"
      ).style("stroke-width", 2
      )

    rectangles = d3.select(self.node).select(".rectangles").selectAll("rect").data(data)
    updateRectangles rectangles.enter().append("rect")
    updateRectangles rectangles.transition().duration(250).ease("cubic-out")
    rectangles.exit().transition().duration(250).attr("r", 0).remove()

    updateLabels = (group) ->
      group.attr("x", (datum) ->
        (datum.x + 0.1*datum.w) * width
      ).attr("y", (datum) ->
        (datum.y + 0.5*datum.h) * height
      ).text( (datum) ->
        datum.name || ''
      ).style("font-size", (datum) ->
        "10px"
      )

    labels = d3.select(self.node).select(".labels").selectAll("text").data(data)
    updateLabels labels.enter().append("text")
    updateLabels labels.transition().duration(250).ease("cubic-out")
    labels.exit().transition().duration(250).attr("r", 0).remove()

Template.viewTable.isModifiable = ->
  t = Session.get 'table'
  isModifiable t

Template.viewTable.df = ->
  t = Session.get 'table'
  t.df

Template.viewTable.chi2 = ->
  t = Session.get 'table'
  toFixed t.chi2, 2

Template.viewTable.gstat = ->
  t = Session.get 'table'
  toFixed t.gstat, 2

Template.viewTable.pvalue = ->
  t = Session.get 'table'
  toFixed t.pvalue, 3

Template.viewTable.rowspan = ->
  t = Session.get 'table'
  t.dim[0] + 1

Template.viewTable.colspan = ->
  t = Session.get 'table'
  t.dim[1] + 1

Template.viewTable.eachrow = ->
  t = Session.get 'table'
  {'row': e} for e in [0...t.dim[0]]

Template.viewTable.eachcol = ->
  t = Session.get 'table'
  {'col': e} for e in [0...t.dim[1]]

Template.viewTable.cell = (r, c) ->
  t = Session.get 'table'
  t.datmarg[MixedBase.decode [r, c], t.dimarg ]

rgbToHex = (r, g, b) ->
  "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)

frgbToHex = (r, g, b) ->
  rgbToHex Math.floor(255*r), Math.floor(255*g), Math.floor(255*b)

Template.viewTable.cellcolor = (r, c) ->
  t = Session.get 'table'
  mi = t.mi[MixedBase.decode [r, c], t.dim ]
  mi *= 35
  if mi >= 0
    x = mi / (1 + mi)
    frgbToHex 1 - x, 1 - x, 1
  else
    mi = - mi
    x = mi / (1 + mi)
    frgbToHex 1, 1 - x, 1 - x

Template.viewTable.c0item = (r) ->
  t = Session.get 'table'
  t.categories[0][r]

Template.viewTable.c1item = (c) ->
  t = Session.get 'table'
  t.categories[1][c]

Template.viewTable.firstrow = (r) ->
  r is 0

Template.viewTable.mrow = (c) ->
  t = Session.get 'table'
  t.datmarg[MixedBase.decode [t.dim[0], c], t.dimarg]

Template.viewTable.mcol = (r) ->
  t = Session.get 'table'
  t.datmarg[MixedBase.decode [r, t.dim[1]], t.dimarg]

Template.viewTable.title = ->
  t = Session.get 'table'
  t.title

Template.viewTable.description = ->
  t = Session.get 'table'
  t.description

Template.viewTable.v0 = ->
  t = Session.get 'table'
  t.variables[0]

Template.viewTable.v1 = ->
  t = Session.get 'table'
  t.variables[1]

Template.viewTable.grandtotal = ->
  t = Session.get 'table'
  _.last t.datmarg

Template.viewTable.events
  'click #viewclose': (event, template) ->
    Session.set 'showViewTable', false
    Session.set 'table', {}

  'click #viewedit': (event, template) ->
    console.log 'Editing!'
    Session.set 'showViewTable', false
    Session.set 'showEditTable', true

  'click #viewdelete': (event, template) ->
    t = Session.get 'table'
    console.log "attempting to delete table #{t._id}!"
    Tables.remove t._id, (error) ->
      Session.set 'showViewTable', false
      Session.set 'table', {}

###########################################################
# Template.editTable
Template.editTable.rowspan = ->
  t = Session.get 'table'
  t.dim[0] + 1

Template.editTable.colspan = ->
  t = Session.get 'table'
  t.dim[1] + 1

Template.editTable.eachrow = ->
  t = Session.get 'table'
  {'row': e} for e in [0...t.dim[0]]

Template.editTable.eachcol = ->
  t = Session.get 'table'
  {'col': e} for e in [0...t.dim[1]]

Template.editTable.cell = (r, c) ->
  t = Session.get 'table'
  t.data[MixedBase.decode [r, c], t.dim ]

Template.editTable.c0item = (r) ->
  t = Session.get 'table'
  t.categories[0][r]

Template.editTable.c1item = (c) ->
  t = Session.get 'table'
  t.categories[1][c]

Template.editTable.firstrow = (r) ->
  r is 0

Template.editTable.mrow = (c) ->
  t = Session.get 'table'
  t.datmarg[MixedBase.decode [t.dim[0], c], t.dimarg]

Template.editTable.mcol = (r) ->
  t = Session.get 'table'
  t.datmarg[MixedBase.decode [r, t.dim[1]], t.dimarg]

Template.editTable.title = ->
  t = Session.get 'table'
  t.title

Template.editTable.description = ->
  t = Session.get 'table'
  t.description

Template.editTable.v0 = ->
  t = Session.get 'table'
  t.variables[0]

Template.editTable.v1 = ->
  t = Session.get 'table'
  t.variables[1]

Template.editTable.grandtotal = ->
  t = Session.get 'table'
  _.last t.datmarg

Template.editTable.publicq = ->
  t = Session.get 'table'
  t.publicq

Template.editTable.events
  'click #publicq': (event, template) ->
    t = Session.get 'table'
    t.publicq = event.target.checked
    console.log "public status is now #{t.publicq}"
    Session.set 'table', t

  'click #editcancel': (event, template) ->
    t = Session.get 'table'
    if t._id
      t = Tables.findOne t._id
      ContingencyTable.updateAll t
      Session.set 'table', t
      Session.set 'showEditTable', false
      Session.set 'showViewTable', true
    else
      Session.set 'table', {}
      Session.set 'showEditTable', false
      Session.set 'showViewTable', false

  'click #editsave': (event, template) ->
    t = Session.get 'table'
    if t._id
      ContingencyTable.updateAll t
      Session.set 'table', t
      Meteor.call "updateTable", t, (error) ->
        if error
          console.log 'ERROR: Could not update table'
          console.log t
        else
          newt = Tables.findOne t._id
          ContingencyTable.updateAll newt
          Session.set 'table', newt
          Session.set 'showEditTable', false
          Session.set 'showViewTable', true
    else
      # ContingencyTable.updateAll t
      Meteor.call "createTable", t, (error, tableid) ->
        if error
          console.log 'ERROR: Could not insert table'
          console.log t
        else
          newt = Tables.findOne tableid
          ContingencyTable.updateAll newt
          Session.set 'table', newt
          Session.set 'showEditTable', false
          Session.set 'showViewTable', true

  'keyup input.title': (event, template) ->
    val = event.target.value
    t = Session.get 'table'
    console.log "updating title = #{val}"
    t.title = val
    Session.set 'table', t

  'keyup input.description': (event, template) ->
    val = event.target.value
    t = Session.get 'table'
    console.log "updating description = #{val}"
    t.description = val
    Session.set 'table', t

  'keyup input.variable': (event, template) ->
    val = event.target.value
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^variable/, ''), 10
    console.log "updating variable[#{j}] = #{val}"
    t.variables[j] = val
    Session.set 'table', t

  'keyup input.category': (event, template) ->
    val = event.target.value
    t = Session.get 'table'
    [r, c] = (event.target.name.replace /^category/, '').split(',').map( (x) -> parseInt(x,10))
    console.log "updating category[#{r}][#{c}] = #{val}"
    t.categories[r][c] = val
    Session.set 'table', t

  'keyup input.cell': (event, template) ->
    val = parseFloat(event.target.value, 10)
    t = Session.get 'table'
    rc = (event.target.name.replace /^cell/, '').split(',').map( (x) -> parseInt(x,10))
    j = MixedBase.decode rc, t.dim
    console.log "updating cell[#{rc}=#{j}] = #{val}"
    t.data[j] = val
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .deleterow': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deleterow/, ''), 10
    return unless 0 <= j < t.dim[0] and 2 < t.dim[0]
    console.log "deleting row #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[0].splice j, 1
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .deletecol': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deletecol/, ''), 10
    return unless 0 <= j < t.dim[1] and 2 < t.dim[1]
    console.log "deleting column #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[1].splice j, 1
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertrow': (event, template) ->
    t = Session.get 'table'
    j = t.dim[0]
    console.log "inserting row #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[0].push j
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertcol': (event, template) ->
    t = Session.get 'table'
    j = t.dim[1]
    console.log "inserting col #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[1].push j
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t
