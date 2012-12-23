"""
A wrapper to ipdb.  Commands are sent between vim and ipdb via tmux.

"""

# Copyright (c) 2012 i3D Technologies, Inc. All rights reserved.


import sys
import os
import traceback
from optparse import OptionParser

from bdb import Breakpoint
from ipdb.__main__ import def_colors, Pdb, Restart


vim_server = None


def red(msg):
    return '\033[91m' + msg + '\033[0m'


def blue(msg):
    return '\033[94m' + msg + '\033[0m'


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
    vim_server = options.servername
    os.system('vim --servername %s --remote-expr "%s"' % (vim_server, cmd))


def main():
    '''Main loop taken from ipdb.'''

    mainpyfile = args[0]     # Get script filename

    if not os.path.exists(mainpyfile):
        print 'Error:', mainpyfile, 'does not exist'
        sys.exit(1)

    debugfile = options.target
    if debugfile is None:
        debugfile = mainpyfile
        dargs = args[1:]
    else:
        dargs = args[2:]

    # Replace pdb's dir with script's dir in front of module search path.
    sys.path[0] = os.path.dirname(mainpyfile)

    vimpdb = VimPdb(def_colors)

    fargs = debugfile + ' ' + ' '.join(dargs)
    line = red('-' * (len(fargs) + 10))
    print line
    print red('DEBUG:  ') + fargs
    print line

    restart = True
    try:
        vimpdb._runscript(mainpyfile)

        if vimpdb._user_requested_quit:
            restart = False

        else:
            print blue('Program completed.')

    except Restart:
        sys.exit(1)  # auto restart

    except SystemExit:
        code = sys.exc_info()[1]
        print blue('Exited:  ') + 'sys.exit(%s)' % code

    except:
        print blue('\n--- EXCEPTION ---')
        #traceback.print_exc()
        exc_lines = traceback.format_exc().splitlines()
        for k, line in enumerate(exc_lines):
            if debugfile in line:
                break

        for line in exc_lines[k:]:
            print line

        print blue('\n--- BEGIN POST-MORTEM ---')

        try:
            t = sys.exc_info()[2]
            vimpdb.interaction(None, t)

            if vimpdb._user_requested_quit:
                restart = False

        except Restart:
            sys.exit(1)  # auto restart

        finally:
            print blue('--- END POST-MORTEM ---')

    if restart:
        raw_input(blue('\nPRESS ANY KEY TO RESTART\n'))
        sys.exit(1)

    else:
        send_vim('semicolon#end_debug()')
        sys.exit(0)


if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option('-s', '--servername', dest='servername', default='VIM',
            help='vim servername obtained with vim --serverlist')

    parser.add_option('-t', '--target', dest='target',
            help='the target file which is the source of the stack traces')

    (options, args) = parser.parse_args()
    sys.argv = args  # set the system args correctly - minus the wrapper

    main()
