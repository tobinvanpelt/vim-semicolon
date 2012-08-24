Semicolon
=========

Semicolon is a pytyhon IDE for vim that utilizes shell based workflow (zsh
recommended) that is manged with tmux. It incorporates an ipython console,
testing using nose, and the debugging of both regular scripts
and test modules.

To utilize semicolon vim must be run from within a tmux seesion:

    $tmux new vim

The IDE consists of vim as the 'edit' pane, a 'debug' pane where the ipdb
debugger executes, and a 'ipython' pane.  Tmux is used to organize these
various panes.  Most of the time only the 'edit' pane is visible, but the
console can toggle open/close using `;;`.  When the console is not visible
beneath the 'edit' pane, the console panes are in their own 'console' window
that can be navigated to with typical tmux commands. This seperate console
window has an additional shell pane as well for conveince.

Breakpoints for debugging are directly entered into python .py files with the
convenience of `;<space>` (see below). Furthermore, you may list or delete all
breakpoints within the project.  The project is defined by the project that was
in effect (using virtualenvwrapper) at the time vim was started. Otherwise the
project defaults to only the current directory and does not incorporate
additional subdirectories.

Note: tmux by default (conveniently for this plugin) binds ';' to 'last-pane' -
this a convenient binding to remember to switch to the console pane and then
back to vim quickly.


Dependencies
------------
Semicolon depends on tmux as well as the following python moduels: 
    
    - nose
    - ipython
    - ipdb


Key Commands
------------
Console:

- `;;`  toggles open/close the console split pane below vim
- `;i`  open console and select ipython pane
- `;ii` reset ipython pane and select it


Breakpoints:

- `;<space>` toggles a breakpoint on/off for the current line in a .py file
- `;b` toggles a window listing of all breakpoints in the quickfix buffer
- `;x` delete all breakpoints in the current project

Debugging:

- `;r`  runs the current .py file
- `;rr` prompts for arguments to run the current .py file
- `;R`  prompts for filename and arguments to run 
- `;d`  debugs the current python test file (uses nosetests)

Testing:

- `;T`  runs all project tests
- `;t`  runs the curretn python test file
- `;tt` prompts for nosetests to run in current test file


Additional useful quickfix commands for the breakpoint list or test failures:

- `:cwindow` opens the quickfix window
- `:cclose` closes the quickfix window
- `:cnext` goto the next breakpoint
- `:cprevious` goto to the previous breakpoint
- `:cc` goto the current breakpoint
- `:cr` goto the begining of the list

    
Commands
--------

- `:SemicolonToggleBreakpoint` (at current line)
- `:SemicolonClearBreakpoints` (within current project scope)
- `:SemicolonToggleBreakpointsList` (for current project scope)

- `:SemicolonRunAllTests` (within current project scope)
- `:SemicolonRunTest` <test> (run current test file or <test> within current) 

- `:SemicolonRun` <arguments> (pass in <arguments> to current file)
- `:SemicolonDebugTest` (run the current test file)

- `:SemicolonToggleConsole`


Configuration
-------------

To redefine the breakpoint command use the following in your .vimrc:

    let g:semicolon_breakpoint=<new breakpoint line>

The default is:

    import ipdb; ipdb.set_trace()


Todos and Future Functionality
------------------------------

- change name of breakpoint buffer sub window
- highlight breakpoints in file
- travel to breakpoint when navigating up down in breakppoint window with
  preview
- put the name of the next line to be executed in the breakpoint list

- when running tests comment out all breakpoints
- when deleting a breakpoint - preserve the yank buffer

- debug just a specific test from the quickfix window
- allow for project to be defined from within semicolon

- configure to be used with python/ipyton or pdb/ipdb


License
-------
Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
See :help license.
