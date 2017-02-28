assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/grid-notation.coffee
"
GN = GridNotation.notation
Unit = GridNotation.unit
Command = GridNotation.command

describe 'Units', ->

  describe 'Object from string', ->

    it 'should return null if given nothing', ->
      assert.strictEqual Unit.parse(""), null
      assert.strictEqual Unit.parse(), null

    it 'should return null when a bad value is given', ->
      assert.strictEqual Unit.parse("foo"), null
      assert.strictEqual Unit.parse("1foo"), null

    it 'should return null base if nothing is given', ->
      assert.strictEqual Unit.parse("1foo"), null

    it 'should return a unit object when a unit pair is given', ->
      assert.deepEqual Unit.parse("1px"),
        string: "1px"
        value: 1
        type: "px"
        base: 1

    it 'should should allow spaces', ->
      assert.deepEqual Unit.parse("1 px"),
        string: "1px"
        value: 1
        type: "px"
        base: 1

    it 'should return a unit object when a pica/point is given', ->
      assert.deepEqual Unit.parse("-0p1"),
        string: "-0p1"
        value: -1
        type: "points"
        base: -1
      assert.deepEqual Unit.parse("0p1"),
        string: "0p1"
        value: 1
        type: "points"
        base: 1
      assert.deepEqual Unit.parse("1p"),
        string: "1p"
        value: 6
        type: "points"
        base: 6
      assert.deepEqual Unit.parse("1p1"),
        string: "1p1"
        value: 7
        type: "points"
        base: 7
      assert.deepEqual Unit.parse("1p1.5"),
        string: "1p1.5"
        value: 7.5
        type: "points"
        base: 7.5

    it 'calculates point/pica notation correctly', ->
      assert.equal Unit.parse("1p").base, Unit.parse("0p6").base
      assert.equal Unit.parse("1p").base, Unit.parse("1pica").base
      assert.equal Unit.parse("1p").base, Unit.parse("6points").base

    it 'should allow integers and floating point numbers', ->
      assert.deepEqual Unit.parse("1"), 1
      assert.deepEqual Unit.parse(".5"), .5

  describe 'Base value from unit object', ->

    it 'should return null when a bad value is given', ->
      assert.deepEqual Unit.asBaseUnit(Unit.parse("foo")), null

    it 'should return an integer when one is given', ->
      assert.deepEqual Unit.asBaseUnit(), null
      assert.deepEqual Unit.asBaseUnit({}), null
      assert.deepEqual Unit.asBaseUnit(""), null

    it 'should return an integer when given a unit object', ->
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1cm")), 28.346456692913385
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1in")), 72
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1mm")), 2.8346456692913384
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1px")), 1
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1pt")), 1
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1pica")), 6
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1p")), 6
      assert.deepEqual Unit.asBaseUnit(Unit.parse("0p1")), 1

    it 'should adjust for resolution when resolution is given', ->
      Unit.resolution = 300
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1in")), 300
      Unit.resolution = 72

  describe 'Preferred name', ->

    it 'should not get the preferred name if nothing is given', ->
      assert.equal Unit.preferredName(), null
      assert.equal Unit.preferredName(""), null

    it 'should get preferred name for unit strings', ->

      assert.equal Unit.preferredName(), null
      assert.equal Unit.preferredName(""), null

      cm = ['centimeter', 'centimeters', 'centimetre', 'centimetres', 'cm']
      for str in cm
        assert.equal Unit.preferredName(str), "cm"

      for str in ['inch', 'inches', 'in']
        assert.equal Unit.preferredName(str), "in"

      mm = ['millimeter', 'millimeters', 'millimetre', 'millimetres', 'mm']
      for str in mm
        assert.equal Unit.preferredName(str), "mm"

      for str in ['pixel', 'pixels', 'px']
        assert.equal Unit.preferredName(str), "px"

      for str in ['point', 'points', 'pts', 'pt', 'p']
        assert.equal Unit.preferredName(str), "points"

      for str in ['pica', 'picas']
        assert.equal Unit.preferredName(str), "picas"

      for str in ['percent', 'pct', '%']
        assert.equal Unit.preferredName(str), "%"

  describe 'To string', ->

    it 'should return null when given nothing', ->
      assert.strictEqual Unit.stringify(), null
      assert.strictEqual Unit.stringify(""), null

    it 'should return string when given a unit object', ->
      assert.equal Unit.stringify(Unit.parse("1px")), "1px"

    it 'should return string when given a string', ->
      assert.equal Unit.stringify("1px"), "1px"

    it 'should return pica/point notation for all forms of picas or points', ->
      assert.equal Unit.stringify("1point"), "0p1"
      assert.equal Unit.stringify("1pica"), "1p"
      assert.equal Unit.stringify("0p1"), "0p1"
      assert.equal Unit.stringify("1p"), "1p"
      assert.equal Unit.stringify("1p0"), "1p"
      assert.equal Unit.stringify("1p1.5"), "1p1.5"
      assert.equal Unit.stringify("1.5p1.5"), "1p4.5"
      assert.equal Unit.stringify("1.5pica"), "1p3"
