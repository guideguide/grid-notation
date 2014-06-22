class GridNotation

  constructor: (args = {}) ->
    @unit = new Unit()
    @cmd = new Command()

  # Convert a GridNotation string into an array of guides.
  #
  #   string - GridNotation string to parse
  #   info   - information about the document
  #
  # Returns an Array.
  parse: (string = "", info = {}) ->
    @unit.resolution = info.resolution if info.resolution
    @cmd.unit = @unit
    guides = []
    tested = @validate(@objectify(string))
    return null if tested.errors.length > 0

    gn = tested.obj
    for key, variable of gn.variables
      gn.variables[key] = @expandCommands variable, variables: gn.variables

    for grid in gn.grids
      guideOrientation = grid.params.orientation
      wholePixels      = grid.params.calculation is 'p'
      fill             = find(grid.commands, (el) -> el.isFill)[0] || null
      originalWidth    = if guideOrientation == 'h' then info.height else info.width
      measuredWidth    = if guideOrientation == 'h' then info.height else info.width
      measuredWidth    = grid.params.width.unit.base if grid.params.width?.unit?.base
      offset           = if guideOrientation == 'h' then info.offsetY else info.offsetX
      stretchDivisions = 0
      adjustRemainder  = 0

      # Expand any fills or variables
      grid.commands = @expandCommands grid.commands, gn.variables

      wildcards = find grid.commands, (el) -> el.isWildcard

      # Measure explicit commands
      explicit = find grid.commands, (el) -> el.isExplicit and !el.isFill
      explicitSum = 0
      explicitSum += command.unit.base for command in explicit

      # If a width was specified, position it. If it wasn't, subtract the offsets
      # from the boundaries.
      if grid.params.width?.unit?.base
        adjustRemainder = originalWidth - grid.params.width?.unit.base
      else
        adjustRemainder = originalWidth - explicitSum if wildcards.length == 0
        measuredWidth -= grid.params.firstOffset?.unit?.base || 0
        measuredWidth -= grid.params.lastOffset?.unit?.base || 0
      if adjustRemainder > 0
        adjustRemainder -= grid.params.firstOffset?.unit?.base || 0
        adjustRemainder -= grid.params.lastOffset?.unit?.base || 0

      # Calculate wild offsets
      stretchDivisions++ if grid.params.firstOffset?.isWildcard
      stretchDivisions++ if grid.params.lastOffset?.isWildcard
      adjust = adjustRemainder/stretchDivisions
      if grid.params.firstOffset?.isWildcard
        adjust = Math.ceil(adjust) if wholePixels
        grid.params.firstOffset = @cmd.parse("#{ adjust }px")
      if grid.params.lastOffset?.isWildcard
        adjust = Math.floor(adjust) if wholePixels
        grid.params.lastOffset = @cmd.parse("#{ adjust }px")

      # Adjust the first offset.
      offset += grid.params.firstOffset?.unit.base || 0

      wildcardArea = measuredWidth - explicitSum

      # Calculate fills
      if wildcardArea and fill
        fillIterations = Math.floor wildcardArea/lengthOf(fill, gn.variables)
        fillCollection = []
        fillWidth = 0

        for i in [1..fillIterations]
          if fill.isVariable
            fillCollection = fillCollection.concat gn.variables[fill.id]
            fillWidth += lengthOf(fill, gn.variables)
          else
            newCommand = @cmd.parse(@cmd.toSimpleString(fill))
            fillCollection.push newCommand
            fillWidth += newCommand.unit.base

        wildcardArea -= fillWidth

        newCommands = []
        for command, i in grid.commands
          if command.isFill
            newCommands = newCommands.concat fillCollection
          else
            newCommands.push command
        grid.commands = [].concat newCommands

      # Set the width of any wildcards
      if wildcardArea and wildcards
        wildcardWidth = wildcardArea/wildcards.length

        if wholePixels
          wildcardWidth = Math.floor wildcardWidth
          remainderPixels = wildcardArea % wildcards.length

        for command in wildcards
          command.isWildcard = false
          command.isExplicit = true
          command.isFill = true
          command.multiplier = 1
          command.isPercent = false
          command.unit = @unit.parse("#{ wildcardWidth }px")

      # Adjust for pixel specific grids
      if remainderPixels
        remainderOffset = 0
        if grid.params.remainder == 'c'
          remainderOffset = Math.floor (wildcards.length - remainderPixels)/2
        if grid.params.remainder == 'l'
          remainderOffset = wildcards.length - remainderPixels

        for command, i in wildcards
          if i >= remainderOffset && i < remainderOffset + remainderPixels
            command.unit = @unit.parse("#{ wildcardWidth+1 }px")

      # Figure out where the grid starts
      insertMarker = grid.params.firstOffset?.unit.base
      insertMarker ||= offset

      # Set value of percent commands
      percents = find grid.commands, (el) -> el.isPercent
      for command in percents
        percentValue = measuredWidth*(command.unit.value/100)
        percentValue = Math.floor(percentValue) if wholePixels
        command.unit = @unit.parse("#{ percentValue }px")

      # Remove dupe guides
      newCommands = []
      for command, i in grid.commands
        if !command.isGuide or (command.isGuide and !grid.commands[i-1]?.isGuide)
          newCommands.push command
      grid.commands = [].concat newCommands

      for command in grid.commands
        if command.isGuide
          guides.push
            location: insertMarker
            orientation: guideOrientation
        else
          insertMarker += command.unit.base

    guides

  # Format a GridNotation string according to spec.
  #
  #   string - string to format
  #
  # Returns a String.
  clean: (string = "") =>
    gn = @validate(@objectify(string)).obj
    string = ""

    for key, variable of gn.variables
      string += "#{ key } = #{ @stringifyCommands variable }\n"

    string += "\n" if gn.variables.length > 0

    for grid in gn.grids
      line = ""
      line += @stringifyCommands grid.commands
      line += " #{ @stringifyParams grid.params }"
      string += "#{ trim line }\n"

    trim string.replace(/\n\n\n+/g, "\n")


  # Convert an object of grid inputs into a grid notation string.
  #
  #   grid - Object to stringify.
  #     count          - int, string int: number of columns/rows
  #     width          - unit pair string: width of column/row
  #     gutter         - unit pair string: width of gutter
  #     firstMargin    - unit pair string: left/top margin
  #     lastMargin     - unit pair string: right/bottom margin
  #     columnMidpoint - true, false: split the columns/rows in two
  #     gutterMidpoint - true, false: split the gutters in two
  #     orientation    - h, v
  #     position       - first, center, last
  #     remainder      - first, center, last
  #
  # Returns a String.
  stringify: (data) =>
    data ||= {}
    data.count            = parseInt data.count
    data.width          ||= ''
    data.gutter         ||= ''
    data.firstMargin    ||= ''
    data.lastMargin     ||= ''
    data.columnMidpoint ||= false
    data.gutterMidpoint ||= false
    data.orientation    ||= 'v'
    data.position       ||= 'f'
    data.remainder      ||= 'l'
    data.calculation    ||= ''
    firstMargString       = ''
    varString             = ''
    gridString            = ''
    lastMargString        = ''
    optionsString         = ''

    # Set up the margins, if they exist
    firstMargString = '|' + data.firstMargin.replace(/,|\s+/g,' ').split(' ').join('|') + '|' if data.firstMargin
    lastMargString  = '|' + data.lastMargin.replace(/,|\s+/g,' ').split(' ').reverse().join('|') + '|' if data.lastMargin

    # Set up the columns and gutters variables, if they exist
    if data.count or data.width
      column = if data.width then data.width else '~'
      if data.columnMidpoint

        unit   = @unit.parse(data.width) if data.width
        column = if data.width then "#{ unit.value/2 }#{ unit.type }|#{ unit.value/2 }#{ unit.type }" else "~|~"

      varString += "$#{ data.orientation } = |#{ column }|\n"

      if data.gutter and data.count != 1
        gutter = if data.gutter then data.gutter else '~'
        if data.gutterMidpoint
          unit   = @unit.parse(data.gutter) if data.gutter
          gutter = if data.gutter then "#{ unit.value/2 }#{ unit.type }|#{ unit.value/2 }#{ unit.type }" else "~|~"

        varString  = "$#{ data.orientation } = |#{ column }|#{ gutter }|\n"
        varString += "$#{ data.orientation }C = |#{ column }|\n" if data.count

    # Set up the grid string
    if data.count or data.width
      gridString += "|$#{ data.orientation }"
      gridString += "*" if data.count != 1
      gridString += data.count - 1 if data.count > 1 and data.gutter
      gridString += data.count if data.count > 1 and !data.gutter
      gridString += "|"
      gridString += "|$#{ data.orientation }#{ if data.gutter then 'C' else '' }|" if data.count > 1 and data.gutter

    if (!data.count and !data.width) and data.firstMargin
      gridString += "|"

    if (!data.count and !data.width) and (data.firstMargin or data.lastMargin)
      gridString += "~"

    if (!data.count and !data.width) and data.lastMargin
      gridString += "|"

    if data.firstMargin or data.lastMargin or data.count or data.width
      # Set up the options
      optionsString += " ( "
      optionsString += data.orientation
      optionsString += data.remainder
      optionsString += "p" if data.calculation == "pixel"
      optionsString += " )"

    leftBuffer = rightBuffer = ""
    if data.width
      leftBuffer = "~" if data.position == "last" or data.position == "center"
      rightBuffer = "~" if data.position == "first" or data.position == "center"

    # Bring it all together
    @pipeCleaner "#{ varString }#{ firstMargString }#{ leftBuffer }#{ gridString }#{ rightBuffer }#{ lastMargString }#{ optionsString }".replace(/\|+/g, "|")

  # Test if a GridNotation string is valid.
  #
  #   string = GridNotation to test
  #
  # Returns a Boolean.
  test: (string) =>
    @validate(@objectify(string)).errors.length is 0

  # Create an object of grid data from a Guide Notation String
  #
  #   string - string to parse
  #
  # Returns an object
  objectify: (string = "") =>
    lines = string.split /\n/g
    string = ""
    variables = {}
    grids = []

    for line in lines
      if /^\$.*?\s?=.*$/i.test line
        variable = @parseVariable line
        variables[variable.id] = variable.commands
      else if /^\s*#/i.test line
        # ignored line
      else
        grid = @parseGrid line
        grids.push grid if grid.commands.length > 0

    variables: variables
    grids: grids

  # Process a guide notation object looking for errors. If any exist, mark them
  # and return the results.
  #
  #   obj - guide notation object
  #
  # Returns an Object.
  validate: (obj) =>
    variablesWithWildcards = {}
    errors = []
    error(2, errors) if obj.grids.length <= 0

    for key, commands of obj.variables
      for command in commands
        error(command.errors, errors) if command.errors.length > 0
        id = command.id
        variable = obj.variables[id] if id

        # If an undefined variable is called, we can't do anything with it.
        error(6, errors, command) if id and !variable

        # Fills are only meant to be used once, in one place. Including a fill
        # in a variable likely means it will be used in multiple places. In
        # theory this *could* be used once, but for now, let's just invalidate.
        error(5, errors, command) if command.isFill

        variablesWithWildcards[key] = true if command.isWildcard

    for key, grid of obj.grids
      fills = 0

      # Determine if the adjustments are valid
      first  = grid.params.firstOffset
      width  = grid.params.width
      last   = grid.params.lastOffset
      error(1, errors) if first and first.errors.length > 0
      error(1, errors) if width and width.errors.length > 0
      error(1, errors) if last and last.errors.length > 0

      for command in grid.commands
        error(command.errors, errors) if command.errors.length > 0
        id = command.id
        variable = obj.variables[id] if id

        # If an undefined variable is called, we can't do anything with it.
        error(6, errors, command) if id and !variable

        # Since wildcards don't have an inherent value, it's impossible to
        # calculate a fill variable containing one.
        varHasWildcard = find(variable, (el) -> el.isWildcard).length > 0

        # Fill variables cannot contain wildcards
        error(3, errors, command) if command.isFill and varHasWildcard

        fills++ if command.isFill
        varHasFill = find(variable, (el) -> el.isFill).length > 0

        # count as a fill if it's a variable that contains a fill
        if id and variable and varHasFill
          fills++

        # Fills can only be used once.
        error(4, errors, command) if fills > 1
        error(5, errors, command) if id and variable and varHasFill

    errors: errors.sort()
    obj: obj

  # Convert a string of command and guide commands into an object.
  #
  # Returns a command object
  parseCommands: (string = "") ->
    string = @pipeCleaner string
    commands = []
    return commands if string == ""
    tokens = string.replace(/^\s+|\s+$/g, '').replace(/\s\s+/g, ' ').split(/\s/)

    commands.push(@cmd.parse(token)) for token in tokens

    commands

  # Take an array of commands and apply any multiples
  #
  #   array     - array of commands
  #   variables - variables for expanding
  #
  # Returns an Array
  expandCommands: (commands = [], variables = {}) ->
    commands = @parseCommands commands if typeof commands is "string"
    reparse = true
    varWidths = {}

    while reparse is true
      reparse = false
      # Expand any multipliers
      newCommands = []
      for command in commands
        if command.isFill
          newCommands.push command
        else
          loops = command.multiplier || 1
          for i in [0...loops] by 1
            newCommands.push @cmd.parse(@cmd.toSimpleString(command))
      commands = [].concat newCommands

      # Apply any variables
      newCommands = []
      for command, i in commands
        if command.isVariable and variables and variables[command.id] and !command.isFill
          reparse = true
          newCommands = newCommands.concat(variables[command.id])
        else
          newCommands.push command
      commands = [].concat newCommands

    commands

  # Look into a string to see if it contains commands
  #
  #   string - string to test
  #
  # Returns a Boolean
  isCommands: (string = "") =>
    return false if string is ""
    return true if string.indexOf("|") >= 0 # it has pipes
    commands = @parseCommands string
    return true if commands.length > 1 # it has multiple commands
    return true if commands[0].errors.length is 0 # it has a valid first command
    false

  # Convert a grid string into an object.
  #
  #   string - string to parse
  #
  # Returns an Object.
  parseGrid: (string = "") =>
    regex = /\((.*?)\)/i
    params = regex.exec(string) || []
    string = trim string.replace regex, ''
    commands = @parseCommands string
    commands: commands
    wildcards: find commands, (el) -> el.isWildcard
    params: @parseParams params[1] || ''

  # Deterimine a grid's paramaters
  #
  #   string - string to be parsed
  #
  # Returns an Object.
  parseParams: (string = "") =>
    bits = string.replace(/[\s\(\)]/g,'').split ','
    obj =
      orientation: "h"
      remainder: "l"
      calculation: ""

    if bits.length > 1
      obj[k] = v for k,v of @parseOptions bits[0]
      obj[k] = v for k,v of @parseAdjustments(bits[1] || "")
      return obj
    else if bits.length is 1
      if @isCommands bits[0]
        obj[k] = v for k,v of @parseAdjustments(bits[0] || "")
      else
        obj[k] = v for k,v of @parseOptions bits[0]
    obj

  # Determine a grid's options
  #
  #   string - string to be parse
  #
  # Returns an Object.
  parseOptions: (string = "") ->
    options = string.split ''
    obj = {}
    for option in options
      switch option.toLowerCase()
        when "h", "v"
          obj.orientation = option
        when "f", "c", "l"
          obj.remainder = option
        when "p"
          obj.calculation = option
    obj

  # Determine a grid's position
  #
  #   string - string to be parsed
  #
  # Returns an Object or null if invalid.
  parseAdjustments: (string = "") ->
    adj =
      firstOffset: null
      width: null
      lastOffset: null
    return adj if string is ""

    bits = @expandCommands(string.replace(/\s/,'')).splice(0,5)

    end = bits.length-1
    adj.lastOffset = bits[end] if bits.length > 1 and !bits[end].isGuide
    adj.firstOffset = bits[0] if !bits[0].isGuide

    for el, i in bits
      if bits[i-1]?.isGuide and bits[i+1]?.isGuide
        adj.width = el if !el.isGuide

    adj

  # Determine a variable's id, and gaps
  #
  #   string - variable string to be parsed
  #
  # Return an object
  parseVariable: (string) =>
    bits = /^\$([^=\s]+)?\s?=\s?(.*)$/i.exec(string)
    return null if !bits[2]?
    id: if bits[1] then "$#{ bits[1] }" else "$"
    commands: @parseCommands bits[2]

  # Clean up the formatting of pipes in a command string
  #
  #   string - string to be cleaned
  #
  # Returns a String.
  pipeCleaner: (string = "") ->
    string
      .replace(/[^\S\n]*\|[^\S\n]*/g, '|') # Normalize spaces
      .replace(/\|+/g, ' | ')              # Duplicate pipes
      .replace(/^\s+|\s+$/gm, '')          # Leading and trailing whitespace

  # Convert a command array into a guide notation spec compliant string.
  #
  #   commands - command array
  #
  # Returns a String.
  stringifyCommands: (commands) =>
    string = ""
    string += @cmd.stringify(command) for command in commands
    @pipeCleaner string

  # Convert a grid's params to a guiden notation spec compliant string.
  #
  #   params - grid params object
  #
  # Returns a String.
  stringifyParams: (params) =>
    string = ""
    string += "#{ params.orientation || '' }"
    string += "#{ params.remainder || '' }"
    string += "#{ params.calculation || '' }"

    if params.firstOffset or params.width or params.lastOffset
      string += ", " if string.length > 0

    string += @cmd.stringify(params.firstOffset) if params.firstOffset
    string += "|#{ @cmd.stringify(params.width) }|" if params.width
    string += "|" if params.firstOffset and params.lastOffset and !params.width
    string += @cmd.stringify(params.lastOffset) if params.firstOffset

    if string then "( #{ @pipeCleaner(string) } )" else ''

#
# A command tells the guide parser to move ahead by the specified distance, or
# to add a guide.
#
class Command
  variableRegexp: /^\$([^\*]+)?(\*(\d+)?)?$/i
  explicitRegexp: /^(([-0-9\.]+)?[a-z%]+)(\*(\d+)?)?$/i
  wildcardRegexp: /^~(\*(\d*))?$/i

  constructor: (args = {}) ->
    @unit = new Unit()

  # Test if a command is a guide
  #
  #   command - command to test
  #
  # Returns a Boolean
  isGuide: (command = "") ->
    if typeof command is "string"
      command.replace(/\s/g, '') == "|"
    else
      command.isGuide || false

  # Test if a string is a variable
  #
  #   string - command string to test
  #
  # Returns a Boolean
  isVariable: (command = "") =>
    if typeof command is "string"
      @variableRegexp.test command.replace /\s/g, ''
    else
      command.isVariable || false


  # Test if a command is an arbitray command (unit pair)
  #
  #   string - command string to test
  #
  # Returns a Boolean
  isExplicit: (command = "") =>
    if typeof command is "string"
      return false if !@explicitRegexp.test command.replace /\s/g, ''
      return false if @unit.parse(command) == null
      true
    else
      command.isExplicit || false

  # Test if a command is a wildcard
  #
  #   string - command string to test
  #
  # Returns a Boolean
  isWildcard: (command = "") =>
    if typeof command is "string"
      @wildcardRegexp.test command.replace /\s/g, ''
    else
      command.isWildcard || false

  # Test if a command is a percent
  #
  #   string - command string to test
  #
  # Returns a Boolean
  isPercent: (command = "") ->
    if typeof command is "string"
      unit = @unit.parse(command.replace /\s/g, '')
      unit? and unit.type == '%'
    else
      command.isPercent || false


  # Test if a command does not have a multiple defined, and therefor should be
  # repeated to fill the given area
  #
  #   string - command string to test
  #
  # Returns a Boolean
  isFill: (string = "") ->
    if @isVariable string
      bits = @variableRegexp.exec string
      return bits[2] && !bits[3] || false
    else if @isExplicit string
      bits = @explicitRegexp.exec string
      return bits[3] && !bits[4] || false
    else if @isWildcard string
      bits = @wildcardRegexp.exec string
      return bits[1] && !bits[2] || false
    else
      false

  # Parse a command and return the number of multiples
  #
  #   string - wildcard string to parse
  #
  # Returns an integer
  count: (string = "") ->
    string = string.replace /\s/g, ''
    if @isVariable string
      parseInt(@variableRegexp.exec(string)[3]) || 1
    else if @isExplicit string
      parseInt(@explicitRegexp.exec(string)[4]) || 1
    else if @isWildcard string
      parseInt(@wildcardRegexp.exec(string)[2]) || 1
    else
      null

  # Parse a command into its constituent parts
  #
  #   string - command string to parse
  #
  # Returns an object
  parse: (string = "") ->
    string = string.replace /\s/g, ''
    if @isGuide string
      errors: []
      isGuide: true
    else if @isVariable string
      bits = @variableRegexp.exec string
      errors: []
      isVariable: true
      isFill: @isFill string
      id: if bits[1] then "$#{ bits[1] }" else "$"
      multiplier: @count string
    else if @isExplicit string
      errors: []
      isExplicit: true
      isPercent: @isPercent string
      isFill: @isFill string
      unit: @unit.parse(string)
      multiplier: @count string
    else if @isWildcard string
      errors: if @isFill(string) then [3] else []
      isWildcard: true
      isFill: @isFill string
      multiplier: @count string
    else
      errors: [1]
      string: string

  # Output a command as a string. If it is unrecognized, format it properly.
  #
  #   command - command to be converted to a string
  #
  # Returns an Integer.
  stringify: (command = "") ->
    return command if typeof command is "string"
    string = ""

    if command.isGuide
      string += "|"
    else if command.isVariable
      string += command.id
    else if command.isExplicit
      string += @unit.stringify(command.unit)
    else if command.isWildcard
      string += "~"
    else
      return "" if command.string is ""
      string += command.string

    if command.isVariable or command.isExplicit or command.isWildcard
      string += '*' if command.isFill or command.multiplier > 1
      string += command.multiplier if command.multiplier > 1

    if command.errors.length is 0 then string else "{#{ string } [#{ command.errors.join(',') }]}"

  # Create a command string without a multiplier
  #
  #   command - command to stringify
  #
  # Returns a String.
  toSimpleString: (command = "") ->
    return command.replace(/\*.*/gi, "") if typeof command is "string"
    @stringify(command).replace(/[\{\}]|\*.*|\[\d*\]/gi, "")

#
# Unit is a utility for parsing and validating unit strings
#
class Unit

  resolution: 72

  constructor: (args = {}) ->

  # Parse a string and change it to a unit object
  #
  #   string - unit string to be parsed
  #
  # Returns an object or null if invalid
  parse: (string = "") =>
    string = string.replace /\s/g, ''
    bits = string.match(/([-0-9\.]+)([a-z%]+)?/i)
    return null if !string or string == "" or !bits?
    return null if bits[2] and !@preferredName(bits[2])

    # Integer
    if bits[1] and !bits[2]
      value = parseFloat bits[1]
      return if value.toString() == bits[1] then value else null

    # Unit pair
    string: string
    value: parseFloat bits[1]
    type: @preferredName bits[2]
    base: @asBaseUnit value: parseFloat(bits[1]), type: @preferredName(bits[2])

  # Parse a string and change it to a friendly unit
  #
  #   string - string to be parsed
  #
  # Returns a string or null, if invalid
  preferredName: (string) ->
    switch string
      when 'centimeter', 'centimeters', 'centimetre', 'centimetres', 'cm'
        'cm'
      when 'inch', 'inches', 'in'
        'in'
      when 'millimeter', 'millimeters', 'millimetre', 'millimetres', 'mm'
        'mm'
      when 'pixel', 'pixels', 'px'
        'px'
      when 'point', 'points', 'pts', 'pt'
        'points'
      when 'pica', 'picas'
        'picas'
      when 'percent', 'pct', '%'
        '%'
      else
        null

  # Convert the given value of type to the base unit of the application.
  # This accounts for reslution, but the resolution must be manually changed.
  # The result is pixels/points.
  #
  #   unit       - unit object
  #   resolution - dots per inch
  #
  # Returns a number
  asBaseUnit: (unit) ->
    return null unless unit? and unit.value? and unit.type?

    # convert to inches
    switch unit.type
      when 'cm'     then unit.value = unit.value / 2.54
      when 'in'     then unit.value = unit.value / 1
      when 'mm'     then unit.value = unit.value / 25.4
      when 'px'     then unit.value = unit.value / @resolution
      when 'points' then unit.value = unit.value / @resolution
      when 'picas'  then unit.value = unit.value / 6
      else
        return null

    # convert to base units
    unit.value * @resolution

  # Convert a unit object to a string or format a unit string to conform to the
  # unit string standard
  #
  #   unit = string or object
  #
  # Returns a string
  stringify: (unit = "") =>
    return null if unit == ""
    return @stringify(@parse(unit)) if typeof unit == "string"

    "#{ unit.value }#{ unit.type }"

# Remove leading and trailing whitespace
#
#   string - string to be trimmed
#
# Returns a String.
trim = (string) -> string.replace(/^\s+|\s+$/g, '')

# Find all items in an array that match the iterator
#
#   arr - array
#   iterator - condition to match
#
# Returns a array.
find = (arr, iterator) ->
  return [] unless arr and iterator
  matches = []
  (matches.push el if iterator(el) is true) for el, i in arr
  matches

# Get the total length of the given command.
#
#   command   - command to be measured
#   variables - variables from the guide notation
#
# Returns a Number.
lengthOf = (command, variables) ->
  return command.unit.value * command.multiplier unless command.isVariable
  return 0 if !variables[command.id]

  sum = 0
  for command in variables[command.id]
    sum += command.unit?.base || 0
  sum

# Assign an error code to a command and a master list
#
#   code    - error code to assign
#   master  - the master error array
#   command - the command that caused the error
#
# Returns nothing.
error = (codes, master, command) ->
  codes = [codes] if typeof codes is "number"
  for code in codes
    exists = find(master, ((e, i) -> true if e is code)).length > 0
    master.push code if !exists
    return unless command
    command.errors ||= []
    command.isValid = false
    exists = find(command.errors, ((e, i) -> true if e is code)).length > 0
    command.errors.push code if !exists

if (typeof module != 'undefined' && typeof module.exports != 'undefined')
  module.exports =
    notation: new GridNotation()
    unit: new Unit()
    command: new Command()
else
  window.GridNotation = new GridNotation()
  window.Unit = new Unit()
  window.Command = new Command()
