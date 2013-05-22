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
    Meteor.call 'resetDB'

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
