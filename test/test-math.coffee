assert = require "assert"
GridNotation = require "
  #{ process.cwd() }/src/grid-notation.coffee
"
GN = GridNotation.notation
Unit = GridNotation.unit
Command = GridNotation.command

info =
  hasOpenDocuments: true
  isSelection: false
  width: 100
  height: 100
  offsetX: 0
  offsetY: 0
  ruler: 'pixels'
  existingGuides: []

# There are millions of combinations of things to test. This file includes
# common grid scenarios to see if the math is being done correctly.
describe 'Math', ->

  describe 'explicit', ->

    it 'should place a single guide', ->
      assert.deepEqual GN.parse("""
        |
      """, info), [
        { location: 0, orientation: "h" }
      ]

    it 'should work with arbitray commands', ->
      assert.deepEqual GN.parse("""
        | 10px |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
      ]

    it 'should convert inches', ->
      assert.deepEqual GN.parse("""
        | 1in |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 72, orientation: "h" }
      ]

  describe 'percents', ->

    it 'should handle percents', ->
      assert.deepEqual GN.parse("""
        | 10% |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
      ]

    it 'should calculate percents with wildcards', ->
      assert.deepEqual GN.parse("""
        | 10% | ~ | 10% |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
        { location: 90, orientation: "h" }
        { location: 100, orientation: "h" }
      ]

    it 'should calculate percents in fill variables', ->
      assert.deepEqual GN.parse("""
        $ = | 50% |
        | $* |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 50, orientation: "h" }
        { location: 100, orientation: "h" }
      ]

  describe 'wildcards', ->

    it 'should find midpoints', ->
      assert.deepEqual GN.parse("""
        ~ | ~ (vl)
        ~ | ~ (hl)
      """, info), [
        { location: 50, orientation: "v" }
        { location: 50, orientation: "h" }
      ]

    it 'should find edges', ->
      assert.deepEqual GN.parse("""
        | ~ | (vl)
        | ~ | (hl)
      """, info), [
        { location: 0, orientation: "v" }
        { location: 100, orientation: "v" }
        { location: 0, orientation: "h" }
        { location: 100, orientation: "h" }
      ]

    it 'should work with two columns', ->
      assert.deepEqual GN.parse("""
        | ~ | ~ | (vl)
      """, info), [
        { location: 0, orientation: "v" }
        { location: 50, orientation: "v" }
        { location: 100, orientation: "v" }
      ]

    it 'should work with three rows', ->
      assert.deepEqual GN.parse("""
        | ~ | ~ | ~ | (hlp)
      """, info), [
        { location: 0, orientation: "h" }
        { location: 33, orientation: "h" }
        { location: 66, orientation: "h" }
        { location: 100, orientation: "h" }
      ]

  describe 'variables', ->

    it 'should work with single character variables', ->
      assert.deepEqual GN.parse("""
        $ = 10px
        | $ |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
      ]

    it 'should work with multi-character variables', ->
      assert.deepEqual GN.parse("""
        $foo = 10px
        | $foo |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
      ]

    it 'should work with cascading variables', ->
      assert.deepEqual GN.parse("""
        $ = 10px
        $a = $ | $
        | $a |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 10, orientation: "h" }
        { location: 20, orientation: "h" }
      ]

    it 'should work with a three column grid', ->
      assert.deepEqual GN.parse("""
        $v=|~|
        |$v*3|(vlp)
      """, info), [
        { location: 0, orientation: "v" }
        { location: 33, orientation: "v" }
        { location: 66, orientation: "v" }
        { location: 100, orientation: "v" }
      ]

  describe 'multiples', ->

    it 'should work with arbitrary multiples', ->
      assert.deepEqual GN.parse("""
        10px*3 |
      """, info), [
        { location: 30, orientation: "h" }
      ]

    it 'should work with fills', ->
      assert.deepEqual GN.parse("""
        10px* |
      """, info), [
        { location: 100, orientation: "h" }
      ]

    it 'should work with variable fills', ->
      assert.deepEqual GN.parse("""
        $ = 50px |
        $* |
      """, info), [
        { location: 50, orientation: "h" }
        { location: 100, orientation: "h" }
      ]

    it 'should work with width and gutter', ->
      assert.deepEqual GN.parse("""
        $v = | 10px | 10px |
        $vC = | 10px |
        | $v* | $vC | ( vl, | ~ )
      """, info), [
        { location: 0, orientation: "v" }
        { location: 10, orientation: "v" }
        { location: 20, orientation: "v" }
        { location: 30, orientation: "v" }
        { location: 40, orientation: "v" }
        { location: 50, orientation: "v" }
        { location: 60, orientation: "v" }
        { location: 70, orientation: "v" }
        { location: 80, orientation: "v" }
        { location: 90, orientation: "v" }
      ]


    it 'should parse cascading multiples', ->
      assert.deepEqual GN.parse("""
        $ = 10px
        $a = $*3
        | $a*3 |
      """, info), [
        { location: 0, orientation: "h" }
        { location: 90, orientation: "h" }
      ]

    describe 'adjustments', ->

      it 'should work with a left offset', ->
        assert.deepEqual GN.parse("""
          | 10px | ( 10px )
        """, info), [
          { location: 10, orientation: "h" }
          { location: 20, orientation: "h" }
        ]

      it 'should right align', ->
        assert.deepEqual GN.parse("""
          | 10px | ( ~ | )
        """, info), [
          { location: 90, orientation: "h" }
          { location: 100, orientation: "h" }
        ]

      it 'should work with a right offset', ->
        assert.deepEqual GN.parse("""
          | 10px | ( ~ | 10px )
        """, info), [
          { location: 80, orientation: "h" }
          { location: 90, orientation: "h" }
        ]

      it 'should work with a width', ->
        assert.deepEqual GN.parse("""
          | ~ | ( | 50px | )
        """, info), [
          { location: 0, orientation: "h" }
          { location: 50, orientation: "h" }
        ]

      it 'should work with a left offset and a width', ->
        assert.deepEqual GN.parse("""
          | ~ | ( 10px | 50px | )
        """, info), [
          { location: 10, orientation: "h" }
          { location: 60, orientation: "h" }
        ]

      it 'should work with a right offset and a width', ->
        assert.deepEqual GN.parse("""
          | ~ | ( ~ | 50px | 10px )
        """, info), [
          { location: 40, orientation: "h" }
          { location: 90, orientation: "h" }
        ]

      it 'should work with a right offset and a left offset', ->
        assert.deepEqual GN.parse("""
          | ~ | ( 10px | 10px )
        """, info), [
          { location: 10, orientation: "h" }
          { location: 90, orientation: "h" }
        ]

      it 'should work with a centered left and right offset', ->
        assert.deepEqual GN.parse("""
          | 10px | ( ~ | ~ )
        """, info), [
          { location: 45, orientation: "h" }
          { location: 55, orientation: "h" }
        ]

      it 'should work with a centered left and right offset and wildcard', ->
        assert.deepEqual GN.parse("""
          | ~ | ( ~ | ~ )
        """, info), [
          { location: 0, orientation: "h" }
          { location: 100, orientation: "h" }
        ]

      it 'should work with left, right, and width wildcards', ->
        assert.deepEqual GN.parse("""
          | ~ | ( ~ | ~ | ~ )
        """, info), [
          { location: 0, orientation: "h" }
          { location: 100, orientation: "h" }
        ]

      it 'should work with left, right, and width wildcards', ->
        assert.deepEqual GN.parse("""
          | ~ | ( 10px | ~ | 10px )
        """, info), [
          { location: 10, orientation: "h" }
          { location: 90, orientation: "h" }
        ]

      it 'should work with left, right, and width units', ->
        assert.deepEqual GN.parse("""
          | ~ | ( 10px | 20px | 10px )
        """, info), [
          { location: 10, orientation: "h" }
          { location: 30, orientation: "h" }
        ]

      it 'should work with all guide markers', ->
        assert.deepEqual GN.parse("""
          | ~ | ( | | | | | )
        """, info), [
          { location: 0, orientation: "h" }
          { location: 100, orientation: "h" }
        ]

      it 'should work with a left aligned width larger than the document', ->
        assert.deepEqual GN.parse("""
          | ~ | ( | 200px | )
        """, info), [
          { location: 0, orientation: "h" }
          { location: 200, orientation: "h" }
        ]

      it 'should work with a center aligned width larger than the document', ->
        assert.deepEqual GN.parse("""
          | ~ | ( ~ | 200px | ~ )
        """, info), [
          { location: -50, orientation: "h" }
          { location: 150, orientation: "h" }
        ]

      it 'should work with a right aligned width larger than the document', ->
        assert.deepEqual GN.parse("""
          | ~ | ( ~ | 200px | )
        """, info), [
          { location: -100, orientation: "h" }
          { location: 100, orientation: "h" }
        ]

    describe 'resolution', ->
      highRes =
        hasOpenDocuments: true
        isSelection: false
        width: 100
        height: 100
        offsetX: 0
        offsetY: 0
        resolution: 300
        ruler: 'pixels'
        existingGuides: []

      it 'should respect resolution in inches', ->
        assert.deepEqual GN.parse("""
          | 1in |
        """, highRes), [
          { location: 0, orientation: "h" }
          { location: 300, orientation: "h" }
        ]
