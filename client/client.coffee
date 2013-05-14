Meteor.subscribe "tables"

Meteor.startup ->
  console.log "Hello!"
  blankTable =
    title: ''
    variables: ['', '']
    categories: [['', ''], ['', '']]
    data: [0, 0, 0, 0]
  ContingencyTable.updateMargins blankTable
  Session.set 'table', blankTable
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
    resetDatabase()

###########################################################
# Template.sidebar

Template.sidebar.tableList = ->
  Tables.find {}

Template.sidebar.lookupTableID = ->
  lookupTableID this

Template.sidebar.displayTitle = ->
  displayTitle this

Template.sidebar.events
  "click td": (event, template) ->
    t = Tables.findOne this._id
    ContingencyTable.updateAll t
    Session.set 'table', t
    Session.set 'showViewTable', true
    Session.set 'showEditTable', false
    console.log t

###########################################################
# Template.main
Template.main.showViewTable = ->
  Session.get 'showViewTable'

Template.main.showEditTable = ->
  Session.get 'showEditTable'

###########################################################
# Template.viewTable
Template.viewTable.df = ->
  t = Session.get 'table'
  t.df

Template.viewTable.chisq = ->
  t = Session.get 'table'
  toFixed t.chisq, 2

Template.viewTable.pvalue = ->
  t = Session.get 'table'
  toFixed t.pvalue, 3

Template.viewTable.rowspan = ->
  t = Session.get 'table'
  t.dimensions[0] + 1

Template.viewTable.colspan = ->
  t = Session.get 'table'
  t.dimensions[1] + 1

Template.viewTable.eachrow = ->
  t = Session.get 'table'
  {'row': e} for e in [0...t.dimensions[0]]

Template.viewTable.eachcol = ->
  t = Session.get 'table'
  {'col': e} for e in [0...t.dimensions[1]]

Template.viewTable.cell = (r, c) ->
  t = Session.get 'table'
  t.data[MixedBase.decode [r, c], t.dimensions ]

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
  t.marginrow[c]

Template.viewTable.mcol = (r) ->
  t = Session.get 'table'
  t.margincol[r]

Template.viewTable.title = ->
  t = Session.get 'table'
  t.title

Template.viewTable.v0 = ->
  t = Session.get 'table'
  t.variables[0]

Template.viewTable.v1 = ->
  t = Session.get 'table'
  t.variables[1]

Template.viewTable.grandtotal = ->
  t = Session.get 'table'
  t.grandtotal

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
    console.log "deleting table #{t._id}!"
    Session.set 'showViewTable', false
    Session.set 'table', {}
    Tables.remove t._id

###########################################################
# Template.editTable
Template.editTable.rowspan = ->
  t = Session.get 'table'
  t.dimensions[0] + 1

Template.editTable.colspan = ->
  t = Session.get 'table'
  t.dimensions[1] + 1

Template.editTable.eachrow = ->
  t = Session.get 'table'
  {'row': e} for e in [0...t.dimensions[0]]

Template.editTable.eachcol = ->
  t = Session.get 'table'
  {'col': e} for e in [0...t.dimensions[1]]

Template.editTable.cell = (r, c) ->
  t = Session.get 'table'
  t.data[MixedBase.decode [r, c], t.dimensions ]

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
  t.marginrow[c]

Template.editTable.mcol = (r) ->
  t = Session.get 'table'
  t.margincol[r]

Template.editTable.title = ->
  t = Session.get 'table'
  t.title

Template.editTable.v0 = ->
  t = Session.get 'table'
  t.variables[0]

Template.editTable.v1 = ->
  t = Session.get 'table'
  t.variables[1]

Template.editTable.grandtotal = ->
  t = Session.get 'table'
  t.grandtotal

Template.editTable.events
  'click #editcancel': (event, template) ->
    t = Session.get 'table'
    t = Tables.findOne t._id
    ContingencyTable.updateAll t
    Session.set 'table', t
    Session.set 'showEditTable', false
    Session.set 'showViewTable', true

  'click #editsave': (event, template) ->
    t = Session.get 'table'
    ContingencyTable.updateAll t
    Session.set 'table', t
    Tables.update t._id, t
    console.log 'Saving!'
    Session.set 'showEditTable', false
    Session.set 'showViewTable', true

  'keyup input.title': (event, template) ->
    val = event.target.value
    t = Session.get 'table'
    console.log "updating title = #{val}"
    t.title = val
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
    j = MixedBase.decode rc, t.dimensions
    console.log "updating cell[#{rc}=#{j}] = #{val}"
    t.data[j] = val
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .deleterow': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deleterow/, ''), 10
    return unless 0 <= j < t.dimensions[0] and 2 < t.dimensions[0]
    console.log "deleting row #{j}"
    p = ContingencyTable.identityPermutation t
    p[0].splice j, 1
    ContingencyTable.permute t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .deletecol': (event, template) ->
    t = Session.get 'table'
    j = parseInt (event.target.name.replace /^deletecol/, ''), 10
    return unless 0 <= j < t.dimensions[1] and 2 < t.dimensions[1]
    console.log "deleting column #{j}"
    p = ContingencyTable.identityPermutation t
    p[1].splice j, 1
    ContingencyTable.permute t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertrow': (event, template) ->
    t = Session.get 'table'
    j = t.dimensions[0]
    console.log "inserting row #{j}"
    p = ContingencyTable.identityPermutation t
    p[0].push j
    ContingencyTable.permute t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t

  'click .insertcol': (event, template) ->
    t = Session.get 'table'
    j = t.dimensions[1]
    console.log "inserting col #{j}"
    p = ContingencyTable.identityPermutation t
    p[1].push j
    ContingencyTable.permute t, p
    ContingencyTable.updateMargins t
    Session.set 'table', t
