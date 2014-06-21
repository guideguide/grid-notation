assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/GridNotation.coffee
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

  describe 'Base value from unit object', ->

    it 'should return null when a bad value is given', ->
      assert.deepEqual Unit.asBaseUnit("foo"), null

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
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1pica")), 12

    it 'should adjust for resolution when resolution is given', ->
      Unit.resolution = 300
      assert.deepEqual Unit.asBaseUnit(Unit.parse("1in"), 300), 300
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

      for str in ['point', 'points', 'pts', 'pt']
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
