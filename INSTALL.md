Installation is pretty straightforward:

1. Make sure that your local copy of [cmd-lib](https://github.com/Jan-Bruun-Andersen/cmd-lib)
   is installed and on your PATH.
2. `configure`
3. `install`

By default, `configure` will prepare the installers to be installed in

    %UserProfile%\LocalTools

If you want to install them somewhere else, run `configure` with the `/prefix`
option, e.g.

    configure /prefix "%AppData%\Local\Programs"

before running `install`.

The installer supports a couple of options:

    /? Show help text.
    /v Be verbose.
    /n Dry-run. Do not install, just show commands.

That's it!
