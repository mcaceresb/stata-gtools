gtools 
======

The gtools command is merely a wrapper for some high-level operations to do
with package maintenance. See the [introduction](index) for an overview of the
package and available commands.

Succintly, gtools is a Stata package that provides a fast implementation of
common group commands like collapse, egen, isid, levelsof, contract, distinct,
and so on using C plugins for a massive speed improvement.

This program helps the user manage their gtools installation. While
unnecessary in Linux or OSX, when trying to compile the plugin on Windows
it became apparent that I would need to include a DLL with the package
(in particular the DLL for the hash library). While I try to do this
automatically, I ran into enough problems while developing the plugin that I
felt compelled to include this program.

_Note for Windows users:_ It may be necessary to run `gtools, dependencies` at
the start of your Stata session.

Syntax
------

```stata
gtools [, options]
```

See `gtools, examples` for examples of hwo to use available gtools functions.

Options
-------

- `dependencies` Installs the hash library, spookyhash.dll, which is required
            for the plugin to execute correctly.

- `upgrade` (alias `install_latest`) Upgrades gtools to the latest github version.

- `replace` Replace spookyhash.dll if already installed.

- `dll` Add path to spookyhash.dll to system path.

- `hashlib(str)Custom` path to spookyhash.dll.

- `licenses` Prints the open source projects used in `gtools`

- `verbose` With `licenses`, prints the licenses of the open source projects used in `gtools`

- `examples` (alias `showcase`) print examples of how to use available gtools functions.
