Accounts.ui.config
  passwordSignupFields: 'USERNAME_AND_EMAIL'

Meteor.subscribe 'tables'

Meteor.subscribe 'directory'

blankTable =
  title: ' '
  description: ' '
  variables: ['', '']
  categories: [['', ''], ['', '']]
  data: [0, 0, 0, 0]
  publicq: true

Meteor.startup ->
  console.log 'Hello!'
  Session.set 'showViewTable', false
  Session.set 'showEditTable', false

###########################################################
# Template.body
Template.body.showViewTable = ->
  Session.get 'showViewTable'

Template.body.showEditTable = ->
  Session.get 'showEditTable'

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

Template.tableList.displayThumbnail = ->
  # document.body.appendChild(Meteor.render(this.svg))
  # this.svg
  # this.find()
  # Meteor.render(this.svg)
  if this.svg
    # new Buffer(this.svg).toString('base64') # Node-specific
    btoa(this.svg)

Template.tableList.lookupTableID = ->
  lookupTableID this

Template.tableList.displayTitle = ->
  this.title

Template.tableList.displayOwner = ->
  if this.owner
    owner = Meteor.users.findOne this.owner
    if owner?.username
      return owner.username
  ''

Template.tableList.events
  'click td, tap td': (event, template) ->
    t = Tables.findOne this._id
    console.log "loading table #{this._id}"
    ContingencyTable.updateAll t
    Session.set 'table', t
    Session.set 'showViewTable', true
    Session.set 'showEditTable', false
    console.log t

  'click #addtable, tap #addtable': (event, template) ->
    console.log 'Adding table'
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
# Template.mosaic

# split |-
layoutxy = (t) ->
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i], x:[0, 0], dx:[0, 0]} for e, i in t.data)
  x = 0
  for c in [0...t.dim[1]]
    y = 0
    marg = fmarg[MixedBase.decode [t.dim[0], c], t.dimarg]
    for r in [0...t.dim[0]]
      i = MixedBase.decode [r, c], t.dim
      data[i].dx[0] = marg
      data[i].dx[1] = data[i].a / marg
      data[i].x[0] = x
      data[i].x[1] = y
      data[i].name = "#{t.categories[0][r]}|#{t.categories[1][c]}"
      y += data[i].dx[1]
    x += data[i].dx[0]
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
# t.variables is ['sex', 'eye', 'hair']
# split x:hair, y:eye, x:sex
layoutxyx = (t) ->
  vars = [2, 1, 0]
  disp = [0, 1, 0]
  maxdisp = _.uniq(disp).length
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i], x:[0, 0], dx:[0, 0]} for e, i in t.data)
  x = []
  dx = []
  x[0] = 0
  for va in [0...t.dim[2]]
    # console.log "#{t.variables[2]}=#{t.categories[2][va]}"
    # j = MixedBase.decode (MixedBase.bitpick s, rc, t.dim), t.dimarg
    dx[0] = fmarg[MixedBase.decode [-1, -1, va], t.dimarg]
    x[1] = 0
    for vb in [0...t.dim[1]]
      dx[1] = fmarg[MixedBase.decode [-1, vb, va], t.dimarg]/dx[0]
      x[2] = 0
      for vc in [0...t.dim[0]]
        i = MixedBase.decode [vc, vb, va], t.dim
        dx[2] = data[i].a / dx[1]
        for k in [0...maxdisp]
          data[i].dx[k] = dx[disp.lastIndexOf(k)]
        for dk, k in disp
          data[i].x[dk] += x[k]
        data[i].name = "#{t.categories[0][vc]}#{t.categories[1][vb]}#{t.categories[2][va]}"
        # data[i].name = "#{vc}|#{vb}|#{va}"
        x[2] += dx[2]
      x[1] += dx[1]
    x[0] += dx[0]
  data

# split |-|
# t.variables is ['sex', 'eye', 'hair']
# split y:hair, x:eye, y:sex
@layoutgeneral = (t) ->
  recurselayout = (ox, odx, v, orc) ->
    x = ox.slice(0) # my own private variables
    dx = odx.slice(0) # since JS passes arrays
    rc = orc.slice(0) # by reference
    if v >= t.vars.length
      i = MixedBase.decode rc, t.dim
      data[i].x = x
      data[i].dx = dx
      data[i].name = rc
      return
    itotal = 1.0 / fmarg[MixedBase.decode rc, t.dimarg]
    direction = t.disp[v]
    variable = t.vars[v]
    for c in [0...t.dim[variable]]
      rc[variable] = c
      part = fmarg[MixedBase.decode rc, t.dimarg]
      dx[direction] = odx[direction]*part*itotal
      recurselayout x, dx, v + 1, rc
      x[direction] += dx[direction]

  t.vars ?= [0...t.dim.length].reverse() # or some random perm
  t.disp ?= ((k % 2) for k in [0...t.vars.length]) # or some random perm
  maxdisp = _.uniq(t.disp).length
  fmarg = (e/_.last(t.datmarg) for e in t.datmarg)
  data = ({a: e/_.last(t.datmarg), mi:t.mi[i], x:[0, 0], dx:[0, 0]} for e, i in t.data)
  eps = .02
  recurselayout (eps for i in [0...maxdisp]),
    (1-2*eps for i in [0...maxdisp]),
    0,
    (-1 for i in [0...t.dim.length])
  data

Template.mosaic.rendered = () ->
  self = this
  self.node = self.find 'svg'

  return if self.handle
  self.handle = Deps.autorun () ->
    t = Session.get 'table'
    ContingencyTable.updateAll t
    data = layoutgeneral t
    Session.set('table', t)

    height = width = 300
    d3.select(self.node).attr('viewBox', "0 0 #{width} #{height}")
    colorscale = d3.scale.linear().domain([-1, 0, 1]).range(['red', 'white', 'blue'])
    sigmoid = (x) -> x / (1 + Math.abs(x))

    updateRectangles = (group) ->
      group.attr('x', (datum) ->
        datum.x[0] * width
      ).attr('y', (datum) ->
        datum.x[1] * height
      ).attr('width', (datum) ->
        datum.dx[0] * width
      ).attr('height', (datum) ->
        datum.dx[1] * height
      ).style('fill', (datum) ->
        colorscale(sigmoid(10*datum.mi))
      ).style('stroke', 'black'
      ).style('stroke-width', 2
      )

    rectangles = d3.select(self.node).select('.rectangles').selectAll('rect').data(data)
    updateRectangles rectangles.enter().append('rect')
    updateRectangles rectangles.transition().duration(400).ease('cubic-out')
    rectangles.exit().transition().duration(400).attr('r', 0).remove()

    # http://dabblet.com/gist/5231222
    # http://stackoverflow.com/questions/13241475/how-do-i-include-newlines-in-labels-in-d3-charts
    fontsize = 12
    breaklines = (datum) ->
      el = d3.select this
      el.text ''
      for wi, i in datum.name
        tspan = el.append('tspan').text(t.categories[i][wi])
        if i > 0
          tspan.attr('x', (datum.x[0] + 0.5*datum.dx[0]) * width).attr('dy', fontsize + 'px')

    updateLabels = (group) ->
      group.attr('x', (datum) ->
        (datum.x[0] + 0.5*datum.dx[0]) * width
      ).attr('y', (datum) ->
        (datum.x[1] + 0.5*datum.dx[1] ) * height + fontsize - 2 - (datum.name.length) * fontsize * 0.5
      ).each( breaklines
      ).style('text-anchor', (datum) ->
        'middle'
      ).style('font-size', (datum) ->
        fontsize + 'px'
      )

    labels = d3.select(self.node).select('.labels').selectAll('text').data(data)
    updateLabels labels.enter().append('text')
    updateLabels labels.transition().duration(250).ease('cubic-out')
    labels.exit().transition().duration(250).attr('r', 0).remove()
    Session.set 'data', data
    if isModifiable t
      t.svg = (new XMLSerializer).serializeToString $('.mosaic svg')[0]
      Session.set 'table', t
      Meteor.call 'updateTable', t

Template.mosaic.events
  'click .mosaic, touchend .mosaic': (event, template) ->
    t = Session.get 'table'
    maxdisp = 2
    if t.vars
      t.disp = ((di + 1) % maxdisp for di, i in t.disp)
      t.vars = MixedBase.nextPermutation(t.vars)
    else
      t.disp = ((k % maxdisp) for k in [0...t.vars.length]) # or some random perm
      t.vars = [0...t.dim.length].reverse()
    if isModifiable t
      t.svg = (new XMLSerializer).serializeToString $('.mosaic svg')[0]
      Session.set 'table', t
      Meteor.call 'updateTable', t
    else
      Session.set 'table', t

###########################################################
# Template.viewTable

# hack in case we are running on a nonstandard port, like localhost:3000
Template.viewTable.root = ->
  if location.host is location.hostname
    ''
  else
    "#{location.protocol}//#{location.host}"

Template.viewTable.id = ->
  t = Session.get 'table'
  t._id

Template.viewTable.table2d = ->
  t = Session.get 'table'
  t.variables.length is 2

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
  '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)

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
  'click #viewclose, tap #viewclose': (event, template) ->
    Session.set 'showViewTable', false
    Session.set 'table', {}

  'click #viewedit, tap #viewedit': (event, template) ->
    console.log 'Editing!'
    Session.set 'showViewTable', false
    Session.set 'showEditTable', true

  'click #viewdelete, tap #viewdelete': (event, template) ->
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
  'click #publicq, tap #publicq': (event, template) ->
    t = Session.get 'table'
    t.publicq = event.target.checked
    console.log "public status is now #{t.publicq}"
    Session.set 'table', t

  'click #editcancel, tap #editcancel': (event, template) ->
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

  'click #editsave, tap #editsave': (event, template) ->
    t = Session.get 'table'
    if t._id
      ContingencyTable.updateAll t
      Session.set 'table', t
      Meteor.call 'updateTable', t, (error) ->
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
      Meteor.call 'createTable', t, (error, tableid) ->
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

  'click .deleterow, tap .deleterow': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deleterow/, ''), 10
    return unless 0 <= j < t.dim[0] and 2 < t.dim[0]
    console.log "deleting row #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[0].splice j, 1
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .deletecol, tap .deletecol': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deletecol/, ''), 10
    return unless 0 <= j < t.dim[1] and 2 < t.dim[1]
    console.log "deleting column #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[1].splice j, 1
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertrow, tap .insertrow': (event, template) ->
    t = Session.get 'table'
    j = t.dim[0]
    console.log "inserting row #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[0].push j
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertcol, tap .insertcol': (event, template) ->
    t = Session.get 'table'
    j = t.dim[1]
    console.log "inserting col #{j}"
    p = ContingencyTable.identityCategoryPermutation t
    p[1].push j
    ContingencyTable.permuteCategories t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t
