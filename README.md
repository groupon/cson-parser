# cson-safe

An alternative to [cson](https://github.com/bevry/cson).
Advantages of `cson-safe`:

* A strict subset of CSON that allows only data
* Interface is identical to JSON.{parse,stringify}
* Free of `eval` and intermediate string representations
* Sane parse error messages with line/column

In addition of pure data it allows for simple arithmetic expressions like
addition and multiplication.
This allows more readable configuration of numbers,
the following is a valid strict CSON file:

```coffee
cachedData:
  refreshIntervalMs: 5 * 60 * 1000
```

## Install

`npm install --save cson-safe`

## Usage

```coffee
CSON = require 'cson-safe'
# This will print { a: '123' }
console.log CSON.parse "a: '123'"
```

## FAQ

### Why not just use YAML?

YAML allows for some pretty complex constructs like anchor and alias,
which can behave in unexpected ways, especially with nested objects.
CSON is simpler while still offering most of the niceties of YAML.

### Why not just use JSON?

JSON doesn't offer multi-line strings and is generally a little noisier.
Also sometimes it can be nice to have comments in config files.

### Why not just use CoffeeScript directly?

You don't want data files being able to run arbitrary code.
Even when ran in a proper sandbox, `while(true)` is still possible.
