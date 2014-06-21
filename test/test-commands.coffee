assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/GridNotation.coffee
"
GN = GridNotation.notation
Unit = GridNotation.unit
Command = GridNotation.command

describe 'Commands', ->

  describe 'Evalutations', ->

    it 'should succeed for guides', ->
      assert.equal Command.isGuide("|"), true

    it 'should fail for non-guides', ->
      assert.equal Command.isGuide("foo"), false

    it 'should succeed for variables', ->
      assert.strictEqual Command.isVariable("$"), true
      assert.strictEqual Command.isVariable("$ = | 10px |"), true
      assert.strictEqual Command.isVariable("$foo = | 10px |"), true

    it 'should fail for non-variables', ->
      assert.strictEqual Command.isVariable(""), false
      assert.strictEqual Command.isVariable("foo"), false
      assert.strictEqual Command.isVariable("1"), false
      assert.strictEqual Command.isVariable("1px"), false

    it 'should succeed for explicit commands', ->
      assert.strictEqual Command.isExplicit("1cm"), true
      assert.strictEqual Command.isExplicit("1in"), true
      assert.strictEqual Command.isExplicit("1mm"), true
      assert.strictEqual Command.isExplicit("1px"), true
      assert.strictEqual Command.isExplicit("1pt"), true
      assert.strictEqual Command.isExplicit("1pica"), true
      assert.strictEqual Command.isExplicit("1%"), true

    it 'should fail for non-explicit commands', ->
      assert.strictEqual Command.isExplicit(""), false
      assert.strictEqual Command.isExplicit("1"), false
      assert.strictEqual Command.isExplicit("foo"), false
      assert.strictEqual Command.isExplicit("$"), false
      assert.strictEqual Command.isExplicit("$A = | 10px |"), false

    it 'should succeed for wildcards', ->
      assert.strictEqual Command.isWildcard("~"), true

    it 'should fail for non-wildcards', ->
      assert.strictEqual Command.isWildcard("~10px"), false
      assert.strictEqual Command.isWildcard(""), false
      assert.strictEqual Command.isWildcard("1px"), false
      assert.strictEqual Command.isWildcard("foo"), false
      assert.strictEqual Command.isWildcard("$A"), false

    it 'should succeed for percents', ->
      assert.strictEqual Command.isPercent("10%"), true

    it 'should fail for non-percents', ->
      assert.strictEqual Command.isPercent("%"), false
      assert.strictEqual Command.isPercent("~10px"), false
      assert.strictEqual Command.isPercent(""), false
      assert.strictEqual Command.isPercent("1px"), false
      assert.strictEqual Command.isPercent("foo"), false
      assert.strictEqual Command.isPercent("$"), false

  describe 'Parsing', ->

    it 'should parse guides', ->
      assert.deepEqual Command.parse("|"),
        isValid: true
        isGuide: true

    it 'should parse variables', ->
      assert.deepEqual Command.parse("$"),
        isValid: true
        isVariable: true
        isFill: false
        id: "$"
        multiplier: 1
      assert.deepEqual Command.parse("$foo*2"),
        isValid: true
        isVariable: true
        isFill: false
        id: "$foo"
        multiplier: 2

    it 'should parse wildcards', ->
      assert.deepEqual Command.parse("~"),
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 1
      assert.deepEqual Command.parse("~*2"),
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 2

    it 'should parse explicit', ->
      assert.deepEqual Command.parse("10px*2"),
        isValid: true
        isExplicit: true
        isFill: false
        isPercent: false
        unit:
          string: "10px*2"
          value: 10
          type: "px"
          base: 10
        multiplier: 2

    it 'should parse unknown', ->
      assert.deepEqual Command.parse("foo"),
        isValid: false
        string: "foo"

  describe 'Multiples', ->

    it 'should succeed for fills', ->
      assert.strictEqual Command.isFill("~*"), true
      assert.strictEqual Command.isFill("$*"), true
      assert.strictEqual Command.isFill("1px*"), true

    it 'should fail for non-fills', ->
      assert.strictEqual Command.isFill("foo"), false
      assert.strictEqual Command.isFill("10px*2"), false

    it 'should not count bad values', ->
      assert.equal Command.count("foo"), null

    it 'should count wildcard multiples', ->
      assert.equal Command.count("~"), 1
      assert.equal Command.count("~*"), 1
      assert.equal Command.count("~*2"), 2

    it 'should count explicit multiples', ->
      assert.equal Command.count("1px"), 1
      assert.equal Command.count("1px*"), 1
      assert.equal Command.count("1px*2"), 2

    it 'should count variable multiples', ->
      assert.equal Command.count("$"), 1
      assert.equal Command.count("$*"), 1
      assert.equal Command.count("$*2"), 2

  describe 'Strings', ->

    it 'should convert guide commands to strings', ->
      assert.equal "|", Command.toString
        isValid: true
        isGuide: true

    it 'should convert variable commands to strings', ->
      assert.equal "$", Command.toString
        isValid: true
        isVariable: true
        isFill: false
        id: "$"
        multiplier: 1
      assert.equal "$foo*2", Command.toString
        isValid: true
        isVariable: true
        isFill: false
        id: "$foo"
        multiplier: 2

    it 'should convert wildcard commands to strings', ->
      assert.equal "~", Command.toString
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 1
      assert.equal "~*2", Command.toString
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 2

    it 'should convert explicit commands to strings', ->
      assert.equal "10px*2", Command.toString
        isValid: true
        isExplicit: true
        isFill: false
        isPercent: false
        unit:
          string: "10px*2"
          value: 10
          type: "px"
          base: 10
        multiplier: 2

    it 'should simplify strings', ->
      assert.equal "~", Command.toSimpleString("~*2")
      assert.equal "~", Command.toSimpleString
        isValid: true
        isWildcard: true
        isFill: false
        multiplier: 2
      assert.equal Command.toSimpleString(Command.parse("10px*")), "10px"
