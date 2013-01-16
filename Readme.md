Semicolon
=========

Semicolon creates a development environment within terminal vim for python that
includes integrated debugging (using ipdb) and testing (using nose).

From vim, breakpoints can be set on a python file and ipdb is used for
debugging using a the tmux mutiplexer.  As the user is debugging the file, the
current line is shown within vim.

Semicolon maintains a notion of a current project directory and a tests
directory.  When started if a virtualenv is activated the project for that
virtualenvironment is utilized (see virtualenvwrapper).  If there is no
virtualenv then the current directory is used for both the project and test
directories.

Additionally, the file '.semicolon.vim' is looked for in the current directory
or project directory,  If it exists it is sourced.  This can be used to set
variables such as the test directory:

set g:semicolon_tests_directory = ~/tests


Dependencies and Requirements
-----------------------------
Semicolon requires +clientserver support within terminal vim running within a
tmux session.  In addition the following dependenceis exist: 
    
    - ipdb
    - nose
    - ipdbplugin
    - tmux-utils
                                   
Optionally the following are highly recomended:
    - virtualenv
    - virtualenvwrapper
    - rednose


Installation
------------
It is recomended that you use pathogen to install semicolon.

Additionally follow these steps to install other dependencies:

1. Python dependencies.

    pip install nose
    pip install ipdb
    pip install ipython

    pip install virtualenv
    pip install virtualenvwrapper
    pip install rednose

2. Install tmux.

3. Install tmux-utils.

    git clone git://github.com/tobinvanpelt/tmux-utils.git

4. Install Xserver (on Mac OSX)

5. Compile vim with clientserver support. (use vim --version or :version to see
   if terminal is built with clientserver support). Edit the vim formula and brew
   accordingly:

    --with-x and --with-features=huge and --enable-gui=no


Starting
--------

1. (optional sets project first) workon <project>

2. tmux

3. vim --servername VIM

It is recomended to use the helper script to start semicolon.  To do so put the
following in your startup file (.bashrc, .zshrc, .profile, etc):

    source <install location>/scirpts/semicolon_init 

Then at the command prompt use:

   semicolon <virtualenv project>

This will activate the virtualenv project, start tmux, and launch vim.  The
<virtualenv project> is optional.


Debugging
---------

The debugger works by opening a standard ipdb terminal as a tmux pane directly
below the vim pane.  This allows for the ipdb debuger to be able to interact
with vim files and eases setting breakpoints and viewing code around the
currently executed line.

Breakpoints can be toggled on/off with `;;` and the breakpoint list can be
toggled on/off using `;b`.  To run a file under the ipdb debugger use `;r`
which opens a pane containing an ipdb terminal. See [pdb
manual](http://docs.python.org/2/library/pdb.html) for a list of commands.

Breakpoitns are stored in a `.pdbrc` file in the project directory so that
breakpoitns can persists between vim sessions. Note that breakpoints can also
be set and removed from within the ipdb terminal and they are updated
accordingly in vim. 

Furthermore, tests written for nose can also be debugged.  When debugging these
tests all appropriate fixtures are setup and torn down.


Testing
-------

When running tests in vim the `:make` compiler command is utilized.  Tests are
run using nosetests with a special plugin taht sends results to an error file.
This eror file is then displayed in the quickfix window to quickly navigate to
tests that resilted in error or failed.

The recomended usage of the `rednose` plugin provides coloring for more easy
interpretation of results and the typical `.noserc` can be used to setup
additional preferences for running nosetests.

By default, nosetests are run with `--with-id` so that subsequent runs can be
done with `--failed`.

Note that arguments can be passed to nosetests as always for example:

    :SemicolonNosetests -a __unit__

to run tests with argument `__unit__`.  All tests are collected from within the
tests directory location unless specified otherwise.  Automcompletion is
relative to this location as well.


Commands
------------
- `:SemicolonProjectDirectory <project_dir>` sets the current project directory
(with no argument - reports the project directory)

- `:SemicolonTestsDirectory <tests_dir>` sets the tests directory
(with no argument - reports the tests directory)

- `SemicolonDebugTest`

- `SemicolonNosetests`

- `SemicolonRun`

...

Hot Keys
--------

Breakpoints:

- `;.` shortcut to SetProject

- `;;`  toggles a breakpoint on/off for the current line in a .py file
- `;b`  toggles a window listing of all breakpoints in the project 
- `;x`  delete all breakpoints in the current file
- `;xx` delete all breakpoints in the current project


Debugging:

- `;r`   runs the current python file within ipdb debugger
- `;rr`  runs the current python file within ipdb debugger and halts at first
  line
- `;R`   prompts for python filename and arguments to run with ipdb debugger 

- `;d`  debugs the current python test under the cursor
- `;d`  debugs the current python test under the cursor and halts on first line
- `;D`  debugs a specifc test from prompt (with format module:class.method)

- `;q`  quits the debugger


Testing:

- `;T`  prompts for arguments to run tests
- `;t`  runs the curret python test file
- `;tt` reruns the previously failed tests


Additional useful quickfix commands for the breakpoint list or test failures:

- `:cwindow` opens the quickfix window
- `:cclose` closes the quickfix window
- `:cnext` goto the next breakpoint
- `:cprevious` goto to the previous breakpoint
- `:cc` goto the current breakpoint
- `:cr` goto the begining of the list

    
Note that tmux by default binds ';' to 'last-pane' - this a convenient binding
to remember to switch to the debugger pane and then back to vim quickly.


Todos and Future Functionality
------------------------------

- add/remove conditional breakpoints
- add/remove ignores to a breakpoint
- disable breakpoints


License
-------
Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
See :help license.
