# Grid notation

**This repository is a work in progress and is not yet documented.**

After a few years of using GuideGuide, I became frustrated that I couldn't move beyond simple grid structures. What if I wanted a sidebar? What if I wanted to reposition the grid in the document? Grid notation is a human friendly(ish), written grid language. A string goes in, an array of guides comes out.

For more information, see the [spec](SPEC.md).

A special note: I consider myself a "developer" more than I consider myself a *developer*. I'm positive there are more efficient ways to write this code (ignoring Coffeescript vs Javascript dogma, of course). If you're interested in improving the parsing of grid notation, by all means, submit a pull request and help me learn something new.

### Setup

```
npm install
```

### Development

Grid notation's source is located in *[src/grid-notation.coffee](src/grid-notation.coffee)*. It must be compiled to publish.

Grid notation's tests use [Mocha](http://mochajs.org/). To run the test watcher, run the following in the terminal:

```
script/test
```

### Compile

```
script/compile
```
