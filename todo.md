
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


PDB
-----

With respect to integrating pdb with vim, it would be helpful to be able to:

- See the location of the current stop point in vim with a highlighted line.

- Possibly be able to set highlights in vim as breakpoints rather than using
set_trace() inserts.  This could be accomplished by saving a .pdbrc file in
each project.  This would require pdb be run from the same location every time.

- The .pdbrc woould keep the breakpoints.  The MyPdb would update it by
  overwiting do_break.  In vim :sign place would be set and then the list of
  the :signs would be used to update .pdbrc and the quickfix window. See
  setqflist().

- The :signs will track file edits with hidden marks.

- set up a server runing in vim and a client for each run.  See:
  http://docs.python.org/2/library/multiprocessing.html
  http://nichol.as/zeromq-an-introduction

- pdb howto:
http://www.doughellmann.com/PyMOTW/pdb/

- cmd howto:
http://www.doughellmann.com/PyMOTW/cmd/

The following is an example of how to extend Pdb:

----
import pdb
import sys
import vim


def set_trace():
    MyPdb().set_trace(sys._getframe().f_back)


class MyPdb(pdb.Pdb):
    def preloop(self):
        lineno = self.curframe.f_lineno
        filename = self.curframe.f_code.co_filename
        print ':', filename, lineno
    




