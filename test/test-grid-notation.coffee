assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/GridNotation.coffee
"
GN = GridNotation.notation
Unit = GridNotation.unit
Command = GridNotation.command


describe 'Grid Notation', ->

  describe "Cleaning", ->

    it 'should clean successfully', ->
      gn = """
      $=|10px|
      |$|~|10px|(v)
      """
      expected = """
      $ = | 10px |
      | $ | ~ | 10px | ( vl )
      """
      assert.equal GN.clean(gn), expected

    it 'should clean empty grids', ->
      assert.equal GN.clean("$=|10px|"), "$ = | 10px |"

    it 'should detect bad commands in grids', ->
      gn = """
      $=|10px|
      |$|~|foo|(v)
      """
      expected = """
      $ = | 10px |
      | $ | ~ | {foo} | ( vl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect bad commands in variables', ->
      assert.equal GN.clean("$=|foo|"), "$ = | {foo} |"

    it 'should detect fills in variables', ->
      assert.equal GN.clean("$=|10px*|"), "$ = | {10px*} |"

    it 'should detect bad adjustments', ->
      assert.equal GN.clean("|~|(hl,foo|~|~)"), "| ~ | ( hl, {foo} | ~ | ~ )"

    it 'should detect undefined variables in variables', ->
      gn = """
      $ = ~
      | $a |
      """
      expected = """
      $ = ~
      | {$a} | ( hl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect undefined variables in grids', ->
      assert.equal GN.clean("$ = $a"), "$ = {$a}"

    it 'should detect fill variables containing wildcards', ->
      gn = """
      $ = ~
      $*
      """
      expected = """
      $ = ~
      {$*} ( hl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect fill wildcards', ->
      assert.equal GN.clean("~*"), "{~*} ( hl )"

    it 'should detect multiple fills', ->
      assert.equal GN.clean("10px*|10px*"), "10px* | {10px*} ( hl )"

    it 'should detect multiple fills when used in variables', ->
      gn = """
      $ = 10px*
      $ | 10px*
      """
      expected = """
      $ = {10px*}
      {$} | {10px*} ( hl )
      """
      assert.equal GN.clean(gn), expected

  describe "Parsing", ->

    info =
      hasOpenDocuments: true
      isSelection: false
      width: 100
      height: 100
      offsetX: 0
      offsetY: 0
      ruler: 'pixels'
      existingGuides: []

    it 'should fail when parsing invalid grid notation', ->
      assert.deepEqual GN.parse(), null

    it 'should parse succesfully', ->
      out = [ { location: 10, orientation: 'h' },
      { location: 20, orientation: 'h' },
      { location: 10, orientation: 'v' },
      { location: 20, orientation: 'v' } ]

      assert.deepEqual GN.parse("""
      $ = 10px |
      $ | $ (hl)
      $A = 10%
      10px | $A | (vl)
      """, info), out

  describe "Objectification", ->

    it 'should objectify', ->
      assert.equal GN.objectify("|$|~|foo| (10px|~|10px)").grids.length, 1

  describe 'Stringification', ->

    it 'should stringify command strings', ->
      assert.equal GN.stringifyCommands(GN.parseCommands("|10px|")), "| 10px |"
      assert.equal GN.stringifyCommands(GN.parseCommands("|foo|")), "| {foo} |"

    it 'should stringify params', ->
      gn = GN.parseGrid "|~|(vl, ~|~|~)"
      assert.equal GN.stringifyParams(gn.params), "( vl, ~ | ~ | ~ )"
      gn = GN.parseGrid "|~|(v)"
      assert.equal GN.stringifyParams(gn.params), "( vl )"

  describe 'Parse grid', ->

    it 'should parse grids', ->
      assert GN.parseGrid("|10px|").commands.length is 3
      assert.equal GN.parseGrid("|~|~|").wildcards.length, 2

  describe 'Parse variable declarations', ->

    it 'should parse variables', ->
      assert.deepEqual GN.parseVariable("$ = |"),
        id: "$"
        commands: [
          isValid: true
          isGuide: true
        ]

    it 'should safely parse empty variables', ->
      assert.deepEqual GN.parseVariable("$ = "),
        id: "$"
        commands: []

  describe 'Parse Commands', ->

    it 'should return an empty array when no commands are given', ->
      assert.strictEqual GN.parseCommands().length, 0
      assert.strictEqual GN.parseCommands("").length, 0

    it 'should parse unknown commands', ->
      assert.equal GN.parseCommands("foo")[0].isValid, false

    it 'should parse guide commands', ->
      assert GN.parseCommands("|")[0].isValid

    it 'should parse arbitrary commands', ->
      assert GN.parseCommands("10px")[0].isValid
      assert GN.parseCommands("10px*")[0].isValid
      assert GN.parseCommands("10px*2")[0].isValid

    it 'should parse variable commands', ->
      assert GN.parseCommands("$")[0].isValid
      assert GN.parseCommands("$A*")[0].isValid
      assert GN.parseCommands("$foo*2")[0].isValid

    it 'should parse wildcard commands', ->
      assert GN.parseCommands("~")[0].isValid
      assert GN.parseCommands("~*")[0].isValid is false
      assert GN.parseCommands("~*2")[0].isValid

  describe 'Parse options', ->

    it 'should parse orientation', ->
      assert GN.parseOptions("h").orientation, "h"
      assert GN.parseOptions("v").orientation, "v"

    it 'should overwrite duplicate options', ->
      assert GN.parseOptions("hv").orientation, "v"

    it 'should ignore case for options', ->
      assert GN.parseOptions("H").orientation, "h"

    it 'should parse remainder', ->
      assert GN.parseOptions("f").remainder, "f"
      assert GN.parseOptions("c").remainder, "c"
      assert GN.parseOptions("l").remainder, "l"

    it 'should parse calculation', ->
      assert.equal GN.parseOptions("p").calculation, "p"

    it 'should find first offset', ->
      assert GN.parseAdjustments("~|~|~").firstOffset
      assert GN.parseAdjustments("~|~|").firstOffset
      assert GN.parseAdjustments("~|~").firstOffset
      assert GN.parseAdjustments("~|").firstOffset
      assert GN.parseAdjustments("~").firstOffset

    it 'should find widths', ->
      assert GN.parseAdjustments("~|~|~").width
      assert GN.parseAdjustments("~|~|").width
      assert GN.parseAdjustments("|~|~").width

    it 'should find last offset', ->
      assert GN.parseAdjustments("~|~|~").lastOffset
      assert GN.parseAdjustments("|~|~").lastOffset
      assert GN.parseAdjustments("~|~").lastOffset
      assert GN.parseAdjustments("|~").lastOffset

    it 'should mark single adjustments as first offset', ->
      assert GN.parseAdjustments("~").firstOffset
      assert !GN.parseAdjustments("~").lastOffset

    it 'should return no adjustments when none are given', ->
      assert !GN.parseAdjustments("").firstOffset
      assert !GN.parseAdjustments("").width
      assert !GN.parseAdjustments("").lastOffset

    it 'should detect commands', ->
      assert GN.isCommands '|'
      assert GN.isCommands '10px'

    it 'should detect non-commands', ->
      assert.equal GN.isCommands('foo'), false
      assert.equal GN.isCommands(''), false

  describe 'Validation', ->

    it 'should reject fills in variables', ->
      obj = GN.objectify("$ = 10px*")
      assert.equal GN.validate(obj).isValid, false

    it 'should reject empty grids', ->
      obj = GN.objectify("")
      assert.equal GN.validate(obj).isValid, false

    it 'should reject fill variables containing wildcards', ->
      obj = GN.objectify """
      $ = ~
      $*
      """
      assert.equal GN.validate(obj).isValid, false

    it 'should reject undefined variables in variables', ->
      obj = GN.objectify "$ = $a"
      assert.equal GN.validate(obj).isValid, false

    it 'should reject undefined variables in grids', ->
      obj = GN.objectify """
      $ = 10px
      $a
      """
      assert.equal GN.validate(obj).isValid, false

    it 'should reject multiple fills in grids', ->
      obj = GN.objectify "|10px*|10px*|"
      assert.equal GN.validate(obj).isValid, false

    it 'should reject fills if a variable already contains one', ->
      obj = GN.objectify """
      $ = 10px*
      |10px*|
      """
      assert.equal GN.validate(obj).isValid, false

    it 'should reject bad alignment params', ->
      assert GN.validate(GN.objectify("~ ( ~ | ~ | ~ )")).isValid
      assert !GN.validate(GN.objectify("~ ( foo | ~ | ~ )")).isValid
      assert !GN.validate(GN.objectify("~ ( ~ | foo | ~ )")).isValid
      assert !GN.validate(GN.objectify("~ ( ~ | ~ | foo )")).isValid

  describe 'Utilities', ->

    it 'should clean pipes', ->
      assert.equal GN.pipeCleaner("|10px|~|10px|"), "| 10px | ~ | 10px |"

    it 'should expand commands', ->
      given = [
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 2
      ]
      expected = [
          isValid: true
          isWildcard: true
          isFill: false
          multiplier: 1
        ,
          isValid: true
          isWildcard: true
          isFill: false
          multiplier: 1
      ]

      assert.deepEqual GN.expandCommands(given), expected
