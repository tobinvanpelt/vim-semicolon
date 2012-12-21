Semicolon
=========

Semicolon creates a python debugging (ipdb) and testing (nose) environment
using tmux and terminal vim.  This creates a lightweight version of some IDE
functionality.

Vim must be run within a tmux session and with +clientserver support and given
a servername (see Installation and Configuration below). Note that tmux by
default binds ';' to 'last-pane' - this a convenient binding to remember to
switch to the debugger pane and then back to vim quickly.


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


Testing
-------







Dependencies and Requirements
-----------------------------

Semicolon requires +clientserver support within terminal vim running within a
tmux session.  In addition the following dependenceis exist: 
    
    - [ipdb]
    - [nose]
    - [ipdbplugin]
    - [tmux-utils]

... give pip and build steps here 


Installation
------------

pip install nose
pip install ipdb
pip install ipython

git clone tmux-pane
vim script ???
ipdbplugin


NOTES: 

need +clientserver use vim --version or :version to see

requires xserver to run

to use brew to compile in:

1. Edit formula for vim such that configure sets:

--with-x and --with-features=huge and --enable-gui=no


Key Commands
------------

Project:

- `:SemicolonProject` returns the current project directory
- `:SemicolonProject <project_dir>` sets the current project directory


Breakpoints:

- `;;`  toggles a breakpoint on/off for the current line in a .py file
- `;b`  toggles a window listing of all breakpoints in the project 
- `;x`  delete all breakpoints in the current file
- `;X` delete all breakpoints in the current project


Debugging:

- `;r`  runs the current .py file within ipdb
- `;rr` prompts for arguments to run the current .py file with ipdb
- `;R`  prompts for filename and arguments 

- `;d`  debugs the current python test file (using nosetests --ipdb)
- `;dd` debugs the current python test under cursor (uses nosetests --ipdb)
- `;D`  debugs a specifc test using a prompt (filename:testname)

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


