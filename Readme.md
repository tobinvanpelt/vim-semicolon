Semicolon
=========

Semicolon creates a python debugging (ipdb) and testing (nose) environment
using tmux and terminal vim.  This creates a lightweight version of some IDE
functionality.

Vim must be run within a tmux session and with +clientserver support and given
a servername (see Installation and Configuration below). Note that tmux by
default binds ';' to 'last-pane' - this a convenient binding to remember to
switch to the debugger pane and then back to vim quickly.


have to start vim in tmux and with --servername


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



(Note that when debugging tests all fixtrures are constructed.)


Testing
-------

automatically uses a --errfile plugin which sends machine readable content to
an errorfile so that quickfix can handle it

:compiler nose

.semicolon.vim

recomended to use: rednose
use deault .noserc 

for example :SemicolonNosetests -a __unit__
for example :SemicolonNosetests --failed




Dependencies and Requirements
-----------------------------

Semicolon requires +clientserver support within terminal vim running within a
tmux session.  In addition the following dependenceis exist: 
    
    - [ipdb]
    - [nose]
    - [ipdbplugin]
    - [tmux-utils]

optional virtualenv (and wrapper)

... give pip and build steps here 


Installation
------------

pip install nose
pip install ipdb
pip install ipython
pip install rednose


git clone tmux-pane
vim script ???
ipdbplugin


NOTES: 

- TODO - warning message if no tmux
warning if not run with --servername

give suggestion of alias



need +clientserver use vim --version or :version to see

requires xserver to run

to use brew to compile in:

1. Edit formula for vim such that configure sets:

--with-x and --with-features=huge and --enable-gui=no


Key Commands
------------

Project:

- `:SemicolonSetProject <project_dir>` sets the current project directory
(with no argument - reports the current project)


- `;.` shortcut to SetProject

Breakpoints:

- `;;`  toggles a breakpoint on/off for the current line in a .py file
- `;b`  toggles a window listing of all breakpoints in the project 
- `;x`  delete all breakpoints in the current file
- `;xx` delete all breakpoints in the current project


Debugging:

- `;r`   runs the current python file within ipdb debugger
- `;rr`  runs the current python file within ipdb debugger and halts on first
  line
- `;R`   prompts for python filename and arguments to run with ipdb debugger 

- `;d`  debugs the current python test under the cursor
- `;d`  debugs the current python test under the cursor and halts on first line
- `;D`  debugs a specifc test from prompt (with format module:class.method)

- `;q`  quits the debugger


Testing:

- `;T`  runs all project tests
- `;t`  runs the curret python test file
- `;tt` runs current test under cursor


Additional useful quickfix commands for the breakpoint list or test failures:

- `:cwindow` opens the quickfix window
- `:cclose` closes the quickfix window
- `:cnext` goto the next breakpoint
- `:cprevious` goto to the previous breakpoint
- `:cc` goto the current breakpoint
- `:cr` goto the begining of the list

    
Configuration
-------------

edit this and tie to semicolon# functions

- `:SemicolonToggleBreakpoint` (at current line)
- `:SemicolonClearBreakpoints` (within current project scope)
- `:SemicolonToggleBreakpointsList` (for current project scope)

- `:SemicolonRunAllTests` (within current project scope)
- `:SemicolonRunTest` <test> (run current test file or <test> within current) 

- `:SemicolonRun` <arguments> (pass in <arguments> to current file)
- `:SemicolonDebugTest` (run the current test file)

- `:SemicolonToggleConsole`



Todos and Future Functionality
------------------------------

- travel to breakpoint when navigating up down in breakppoint window with
  preview
- add/remove conditions to a breakpoint 
- add/remove ignores to a breakpoint
- disable breakpoints


License
-------
Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
See :help license.


