assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/grid-notation.coffee
"
GN = GridNotation.notation
Unit = GridNotation.unit
Command = GridNotation.command


describe 'Grid Notation', ->

  describe ".clean()", ->

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
      | $ | ~ | {foo [1]} | ( vl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect bad commands in variables', ->
      assert.equal GN.clean("$=|foo|"), "$ = | {foo [1]} |"

    it 'should detect fills in variables', ->
      assert.equal GN.clean("$=|10px*|"), "$ = | {10px* [5]} |"

    it 'should detect bad adjustments', ->
      assert.equal GN.clean("|~|(hl,foo|~|~)"), "| ~ | ( hl, {foo [1]} | ~ | ~ )"

    it 'should detect undefined variables in variables', ->
      gn = """
      $ = ~
      | $a |
      """
      expected = """
      $ = ~
      | {$a [6]} | ( hl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect undefined variables in grids', ->
      assert.equal GN.clean("$ = $a"), "$ = {$a [6]}"

    it 'should detect fill variables containing wildcards', ->
      gn = """
      $ = ~
      $*
      """
      expected = """
      $ = ~
      {$* [3]} ( hl )
      """
      assert.equal GN.clean(gn), expected

    it 'should detect fill wildcards', ->
      assert.equal GN.clean("~*"), "{~* [3]} ( hl )"

    it 'should detect multiple fills', ->
      assert.equal GN.clean("10px*|10px*"), "10px* | {10px* [4]} ( hl )"
      assert.equal GN.clean("10px* 10px*"), "10px* {10px* [4]} ( hl )"

    it 'should detect multiple fills when used in variables', ->
      gn = """
      $ = 10px*
      $ | 10px*
      """
      expected = """
      $ = {10px* [5]}
      {$ [5]} | {10px* [4]} ( hl )
      """
      assert.equal GN.clean(gn), expected

  describe ".parse()", ->

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

  describe "Testing", ->

    it 'should succeed for good grid notation', ->
      assert GN.test("|10px|")

    it 'should fail for bad grid notation', ->
      assert GN.test("|foo|").length > 0

  describe "Objectification", ->

    it 'should objectify', ->
      assert.equal GN.objectify("|$|~|foo| (10px|~|10px)").grids.length, 1

  describe 'Parse grid', ->

    it 'should parse grids', ->
      assert GN.parseGrid("|10px|").commands.length is 3
      assert.equal GN.parseGrid("|~|~|").wildcards.length, 2

  describe 'Parse variable declarations', ->

    it 'should parse variables', ->
      assert.deepEqual GN.parseVariable("$ = |"),
        id: "$"
        commands: [
          errors: []
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
      assert GN.parseCommands("foo")[0].errors.length > 0

    it 'should parse guide commands', ->
      assert GN.parseCommands("|")[0].errors.length is 0

    it 'should parse arbitrary commands', ->
      assert GN.parseCommands("10px")[0].errors.length is 0
      assert GN.parseCommands("10px*")[0].errors.length is 0
      assert GN.parseCommands("10px*2")[0].errors.length is 0

    it 'should parse variable commands', ->
      assert GN.parseCommands("$")[0].errors.length is 0
      assert GN.parseCommands("$A*")[0].errors.length is 0
      assert GN.parseCommands("$foo*2")[0].errors.length is 0

    it 'should parse wildcard commands', ->
      assert GN.parseCommands("~")[0].errors.length is 0
      assert GN.parseCommands("~*")[0].errors.length > 0
      assert GN.parseCommands("~*2")[0].errors.length is 0

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
      assert GN.validate(obj).errors.length > 0

    it 'should reject empty grids', ->
      obj = GN.objectify("")
      assert GN.validate(obj).errors.length > 0

    it 'should reject fill variables containing wildcards', ->
      obj = GN.objectify """
      $ = ~
      $*
      """
      assert GN.validate(obj).errors.length > 0

    it 'should reject undefined variables in variables', ->
      obj = GN.objectify "$ = $a"
      assert GN.validate(obj).errors.length > 0

    it 'should reject undefined variables in grids', ->
      obj = GN.objectify """
      $ = 10px
      $a
      """
      assert GN.validate(obj).errors.length > 0

    it 'should reject multiple fills in grids', ->
      obj = GN.objectify "|10px*|10px*|"
      assert GN.validate(obj).errors.length > 0

    it 'should reject fills if a variable already contains one', ->
      obj = GN.objectify """
      $ = 10px*
      |10px*|
      """
      assert GN.validate(obj).errors.length > 0

    it 'should reject bad alignment params', ->
      assert GN.validate(GN.objectify("~ ( ~ | ~ | ~ )")).errors.length is 0
      assert GN.validate(GN.objectify("~ ( foo | ~ | ~ )")).errors.length > 0
      assert GN.validate(GN.objectify("~ ( ~ | foo | ~ )")).errors.length > 0
      assert GN.validate(GN.objectify("~ ( ~ | ~ | foo )")).errors.length > 0

  describe 'Utilities', ->

    it 'should clean pipes', ->
      assert.equal GN.pipeCleaner("|10px|~|10px|"), "| 10px | ~ | 10px |"

    it 'should expand commands', ->
      given = [
        errors: []
        isWildcard: true
        isFill: false
        multiplier: 2
      ]
      expected = [
          errors: []
          isWildcard: true
          isFill: false
          multiplier: 1
        ,
          errors: []
          isWildcard: true
          isFill: false
          multiplier: 1
      ]

      assert.deepEqual GN.expandCommands(given), expected

    it 'should stringify command strings', ->
      assert.equal GN.stringifyCommands(GN.parseCommands("|10px|")), "| 10px |"
      assert.equal GN.stringifyCommands(GN.parseCommands("|foo|")), "| {foo [1]} |"

    it 'should stringify params with no adjustments', ->
      gn = GN.parseGrid "|~|(v)"
      assert.equal GN.stringifyParams(gn.params), "( vl )"

    it 'should stringify all adjustments', ->
      gn = GN.parseGrid "|~|(vl, ~|~|~)"
      assert.equal GN.stringifyParams(gn.params), "( vl, ~ | ~ | ~ )"

    it 'should stringify left adjustments', ->
      gn = GN.parseGrid "|~|(vl, ~|)"
      assert.equal GN.stringifyParams(gn.params), "( vl, ~ | )"

    it 'should stringify right adjustments', ->
      gn = GN.parseGrid "|~|(vl, |~)"
      assert.equal GN.stringifyParams(gn.params), "( vl, | ~ )"

    it 'should stringify left and right adjustments', ->
      gn = GN.parseGrid "|~|(vl, ~|~)"
      assert.equal GN.stringifyParams(gn.params), "( vl, ~ | ~ )"

    it 'should stringify left adjustment with width', ->
      gn = GN.parseGrid "|~|(vl, ~|~|)"
      assert.equal GN.stringifyParams(gn.params), "( vl, ~ | ~ | )"

    it 'should stringify right adjustment with width', ->
      gn = GN.parseGrid "|~|(vl, |~|~)"
      assert.equal GN.stringifyParams(gn.params), "( vl, | ~ | ~ )"

  describe '.stringify()', ->

    it 'should stringify first margin', ->
      string = """
        | 10px | ~ ( vl, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px"), string

    it 'should stringify multiple first margins', ->
      string = """
        | 10px | 20px | ~ ( vl, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px 20px"), string

    it 'should stringify last margin', ->
      string = """
        ~ | 10px | ( vl, | ~ )
      """
      assert.equal GN.stringify(lastMargin: "10px"), string

    it 'should stringify multiple last margins', ->
      string = """
        ~ | 20px | 10px | ( vl, | ~ )
      """
      assert.equal GN.stringify(lastMargin: "10px 20px"), string

    it 'should stringify first and last margins', ->
      string = """
        | 10px | ~ | 10px | ( vl, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px", lastMargin: "10px"), string

    it 'should stringify count', ->
      string = """
        $v = | ~ |
        | $v*3 | ( vl, | ~ )
      """
      assert.equal GN.stringify(count: "3"), string

    it 'should stringify count with margins', ->
      data = count: "3", firstMargin: "10px", lastMargin: "10px"
      string = """
        $v = | ~ |
        | 10px | $v*3 | 10px | ( vl, | ~ )
      """
      assert.equal GN.stringify(data), string

    it 'should not stringify gutter by itself', ->
      assert.equal GN.stringify(gutter: "10px"), ""

    it 'should stringify gutter and count', ->
      string = """
        $v = | ~ | 10px |
        $vC = | ~ |
        | $v*2 | $vC | ( vl, | ~ )
      """
      assert.equal GN.stringify(count: "3", gutter: "10px"), string

    it 'should stringify width', ->
      string = """
        $v = | 10px |
        | $v* | ( vl, | ~ )
      """
      assert.equal GN.stringify(width: "10px"), string

    it 'should stringify count and width', ->
      string = """
        $v = | 10px |
        | $v*3 | ( vl, | ~ )
      """
      assert.equal GN.stringify(count: "3", width: "10px"), string

    it 'should stringify width and gutter', ->
      string = """
        $v = | 10px | 10px |
        $vC = | 10px |
        | $v* | $vC | ( vl, | ~ )
      """
      assert.equal GN.stringify(width: "10px", gutter: "10px"), string

    it 'should not stringify only column midpoint', ->
      assert.equal GN.stringify(columnMidpoint: true), ""

    it 'should not stringify only gutter midpoint', ->
      assert.equal GN.stringify(gutterMidpoint: true), ""

    it 'should stringify column midpoint with count', ->
      string = """
        $v = | ~ | ~ |
        | $v*3 | ( vl, | ~ )
      """
      assert.equal GN.stringify(count: "3", columnMidpoint: true), string

    it 'should stringify column midpoint with count and width', ->
      data = count: "3", width: "10px", columnMidpoint: true
      string = """
        $v = | 5px | 5px |
        | $v*3 | ( vl, | ~ )
      """
      assert.equal GN.stringify(data), string

    it 'should stringify gutter midpoint with count and gutter', ->
      data = count: "3", gutter: "10px", gutterMidpoint: true
      string = """
        $v = | ~ | 5px | 5px |
        $vC = | ~ |
        | $v*2 | $vC | ( vl, | ~ )
      """
      assert.equal GN.stringify(data), string

    it 'should not stringify gutter midpoint with count and no gutter', ->
      data = count: "3", gutterMidpoint: true
      string = """
        $v = | ~ |
        | $v*3 | ( vl, | ~ )
      """
      assert.equal GN.stringify(data), string

    it 'should stringify centered grids', ->
      data = count: "3", width: "10px", position: "c"
      string = """
        $v = | 10px |
        | $v*3 | ( vl, ~ | ~ )
      """
      assert.equal GN.stringify(data), string

    it 'should stringify right aligned grids', ->
      data = count: "3", width: "10px", position: "l"
      string = """
        $v = | 10px |
        | $v*3 | ( vl, ~ | )
      """
      assert.equal GN.stringify(data), string

    it 'should stringify pixel calculation', ->
      string = """
        | 10px | ~ ( vlp, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px", calculation: "p"), string

    it 'should stringify first remainder', ->
      string = """
        | 10px | ~ ( vf, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px", remainder: "f"), string

    it 'should stringify center remainder', ->
      string = """
        | 10px | ~ ( vc, | ~ )
      """
      assert.equal GN.stringify(firstMargin: "10px", remainder: "c"), string
