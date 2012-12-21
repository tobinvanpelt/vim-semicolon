"""
A wrapper to ipdb.  Commands are sent between vim and ipdb via tmux.

"""

# Copyright (c) 2012 i3D Technologies, Inc. All rights reserved.


import sys
import os
import traceback

from bdb import Breakpoint
from ipdb.__main__ import def_colors, Pdb, Restart


vim_server = None


class VimPdb(Pdb):
    def preloop(self):
        lineno = self.curframe.f_lineno
        filename = self.curframe.f_code.co_filename

        print filename, lineno

        cmd = "semicolon#set_current_line('%s', %s)" % (filename, lineno)
        send_vim(cmd)

    def precmd(self, line):
        args = line.split(' ')

        if args[0] == 'b' or args[0] == 'break':
            self._process_break(args)

        elif args[0] == 'cl' or args[0] == 'clear':
            self._process_clear(args)

        return line

    def _process_break(self, args):
        if len(args) == 2:
            # set a bp
            fname = None
            lineno = None

            args2 = args[1].split(':')
            if len(args2) == 1:
                fname = self.curframe.f_code.co_filename
                lineno = args2[0]

            elif len(args2) == 2:
                if os.path.exists(args2[0]):
                    fname = args2[0]
                    lineno = args2[1]

            try:
                line_num = int(lineno)

            except ValueError:
                return

            cmd = "semicolon#set_vim_bp('%s', %s)" % (fname, line_num)
            send_vim(cmd)

    def _process_clear(self, args):
        if len(args) == 1:
            # clear all bps
            print 'Only breakpoints locally will be cleared.'
            print 'No vim breakpoints will be effected.'

        else:
            if ':' in args[1]:
                # clear a single bp
                args2 = args[1].split(':')
                if len(args2) == 2:
                    if os.path.exists(args2[0]):
                        fname = args2[0]
                        lineno = args2[1]

                        try:
                            line_num = int(lineno)

                        except ValueError:
                            return

                        cmd = "semicolon#remove_vim_bp('%s', %s)" \
                                % (fname, line_num)
                        send_vim(cmd)

            else:
                # clear by number
                for a in args[1:]:
                    try:
                        _id = int(a)
                        bp = Breakpoint.bpbynumber[_id]

                    except (ValueError, IndexError):
                        continue

                    fname = bp.file
                    line_num = bp.line

                    cmd = "semicolon#remove_vim_bp('%s', %s)" \
                            % (fname, line_num)
                    send_vim(cmd)


def send_vim(cmd):
    os.system('vim --servername %s --remote-expr "%s"' % (vim_server, cmd))


def main():
    '''Main loop taken from ipdb.'''

    global vim_server
    vim_server = sys.argv[1]

    mainpyfile = sys.argv[2]     # Get script filename

    if not os.path.exists(mainpyfile):
        print 'Error:', mainpyfile, 'does not exist'
        sys.exit(1)

    del sys.argv[0]         # Hide "pdb.py" from argument list

    # Replace pdb's dir with script's dir in front of module search path.
    sys.path[0] = os.path.dirname(mainpyfile)

    vimpdb = VimPdb(def_colors)
    while 1:
        try:
            vimpdb._runscript(mainpyfile)
            if vimpdb._user_requested_quit:
                break
            print "The program finished and will be restarted.\n"

        except Restart:
            print "Restarting", mainpyfile, "with arguments:"
            print "\t" + " ".join(sys.argv[2:])

        except SystemExit:
            # In most cases SystemExit does not warrant a post-mortem session.
            print "The program exited via sys.exit(). Exit status: ",
            print sys.exc_info()[1]

        except:
            traceback.print_exc()
            print "Uncaught exception. Entering post mortem debugging"
            print "Running 'cont' or 'step' will restart the program"
            t = sys.exc_info()[2]
            vimpdb.interaction(None, t)
            print "Post mortem debugger finished. The " + mainpyfile + \
                  " will be restarted"

    send_vim('semicolon#end_debug()')


if __name__ == '__main__':
    main()
