"""
vimipdb.py

A wrapper to ipdb that synchrozies with a vim instance running with
+clienterver. This allows breakpoints to be set in vim, saved in .pdbrc, and
then run in another tmux terminal with ipdb.

https://github.com/tobinvanpelt/vim-semicolon.git

"""

# Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
#See :help license.


import os
import sys
import traceback
import types

from optparse import OptionParser


options = {}


def _parse_args():
    parser = OptionParser()
    parser.add_option('-s', '--servername', dest='servername', default='VIM',
            help='vim servername ( result of vim --serverlist )')

    parser.add_option('-p', '--pdbrc', dest='pdbrc', default=None,
            help='alternate pdbrc file')

    parser.add_option('-n', '--nose-test', dest='nosetest',
            action='store_true', default=False,
            help='whether the argument is a nosetest')

    parser.add_option('-c', '--continue', dest='cont',
            action='store_true', default=False,
            help='run with immediate continue')

    return parser.parse_args()


def _send_vim(cmd):
    vim_server = options.servername
    os.system('vim --servername %s --remote-expr "%s"' % (vim_server, cmd))


try:
    import nose

    from bdb import Breakpoint, BdbQuit
    from ipdb.__main__ import def_colors, Pdb, Restart

except ImportError:
    # always end the debugging when import error

    options, args = _parse_args()
    _send_vim('semicolon#end_debug()')
    raise


def red(msg):
    return '\033[91m' + msg + '\033[0m'


def green(msg):
    return '\033[92m' + msg + '\033[0m'


def blue(msg):
    return '\033[94m' + msg + '\033[0m'


def cyan(msg):
    return '\033[96m' + msg + '\033[0m'


class VimPdb(Pdb):
    def __init__(self, *args, **kwds):
        Pdb.__init__(self, *args, **kwds)

        if options.pdbrc is not None:
            try:
                rcFile = open(options.pdbrc)

            except IOError:
                pass

            else:
                for line in rcFile.readlines():
                    self.rcLines.append(line)

                rcFile.close()

        self.cont = False

    def setup(self, f, t):
        Pdb.setup(self, f, t)

        # so 'enter' defaults to continue at start
        self.lastcmd = 'c'

    def runcall_continue(self, fcn, *args, **kwds):
        self.botframe = sys._getframe(0)
        self._set_stopinfo(self.botframe, None, -1)
        sys.settrace(self.trace_dispatch)

        res = None
        try:
            res = fcn(*args, **kwds)

        except:
            raise

        finally:
            self.quitting = 1
            sys.settrace(None)

        return res

    def runscript(self, filename, cont=False):
        # copy _runscript in super class but do not reset is cont=True
        import __main__
        __main__.__dict__.clear()
        __main__.__dict__.update({"__name__": "__main__",
                                  "__file__": filename,
                                  "__builtins__": __builtins__,
                                 })

        self._wait_for_mainpyfile = 1
        self.mainpyfile = self.canonic(filename)
        self._user_requested_quit = 0
        statement = 'execfile(%r)' % filename

        if cont:
            self.execRcLines()
            self.botframe = sys._getframe(0)
            self._set_stopinfo(self.botframe, None, 0)

        else:
            self.reset()

        globals = __main__.__dict__
        locals = globals
        sys.settrace(self.trace_dispatch)

        if not isinstance(statement, types.CodeType):
            statement = statement + '\n'
        try:
            exec statement in globals, locals

        except BdbQuit:
            pass

        finally:
            self.quitting = 1
            sys.settrace(None)

    def preloop(self):
        lineno = self.curframe.f_lineno
        filename = self.curframe.f_code.co_filename

        print filename, lineno

        cmd = "semicolon#set_current_line('%s', %s)" % (filename, lineno)
        _send_vim(cmd)

    def precmd(self, line):
        args = line.split(' ')

        if args[0] == 'b' or args[0] == 'break':
            self._do_break(args)

        elif args[0] == 'cl' or args[0] == 'clear':
            self._do_clear(args)

        elif args[0] == 'l':
            self._do_list()

        return line

    def _do_break(self, args):
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
            _send_vim(cmd)

    def _do_clear(self, args):
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
                        _send_vim(cmd)

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
                    _send_vim(cmd)

    def _do_list(self):
        fname = self.curframe.f_code.co_filename
        cmd = "semicolon#center_line('%s')" % fname
        _send_vim(cmd)


def _line_str(msg=None):
    if msg is None:
        msg = ''

    if msg != '':
        msg = ' ' + msg + ' '

    line = '---' + msg
    line += '-' * (50 - len(line))

    return line


def _post_mortem(entry_file):
    '''Returns restart value: True, False, or None.'''
    vimpdb = VimPdb(def_colors)
    vimpdb.reset()
    vimpdb._user_requested_quit = 0

    etype, value, tb = sys.exc_info()

    # attempt to import and use colorization from rednose
    try:
        from rednose import RedNose

        ftb = RedNose()._fmt_traceback(tb)
        ftb = ftb.split('\n')
        ftb.append('')

        ex_line = red(traceback.format_exception_only(etype, value)[0])
        ftb.append(ex_line)

    except ImportError:
        ftb = traceback.format_exception(etype, value, tb)
        ftb = ''.join(ftb)
        ftb = ftb.split('\n')

    # save the header line and the file entry point
    filename = os.path.basename(entry_file)
    while filename not in ftb[1]:
        try:
            ftb.pop(1)

        except IndexError:
            break

        if len(ftb) == 1:
            break

    ftb.insert(1, '    ...')

    print
    print red(_line_str('EXCEPTION'))

    print '\n'.join(ftb)

    print
    print red(_line_str('BEGIN POST-MORTEM'))

    try:
        vimpdb.interaction(None, tb)

        if vimpdb._user_requested_quit:
            raise BdbQuit()

    finally:
        print red(_line_str('END POST-MORTEM'))


def run(runner, msgs, entry_file):
    ''' Main loop used for debuging.
    sys.exit(0) - immediately end
    sys.exit(1) - allow read of error then end
    sys.exit(2) - prompt for repeat
    sys.exit(3) - repeat
    '''

    (header_msg, exc_msg, end_msg) = msgs

    line = blue(_line_str())
    print line
    print header_msg
    print line

    vimpdb = VimPdb(def_colors)
    vimpdb._user_requested_quit = False

    restart = None
    try:
        runner(vimpdb)

        if vimpdb._user_requested_quit:
            raise BdbQuit()

    except BdbQuit:
        restart = False

    except Restart:
        restart = True

    except SystemExit:
        code = sys.exc_info()[1]
        print blue('Exited with sys.exit(%s).' % code)

    except:
        try:
            _post_mortem(entry_file)

        except BdbQuit:
            restart = False

        except Restart:
            restart = True

        if len(exc_msg) > 0:
            print '\n' + exc_msg

    else:
        if len(end_msg) > 0:
            print '\n' + end_msg

    finally:
        print line

    if restart is None:
        # unknown request
        sys.exit(4)

    else:
        if restart:
            # restart request
            sys.exit(3)

        else:
            # quit request
            sys.exit(0)


def main():
    global options

    options, args = _parse_args()

    if not options.nosetest:
        sys.argv = args  # set the system args correctly - minus the wrapper

        mainpyfile = args[0]     # Get script filename
        if not os.path.exists(mainpyfile):
            print 'Error:', mainpyfile, 'does not exist'
            sys.exit(1)

        # Replace pdb's dir with script's dir in front of module search path.
        sys.path[0] = os.path.dirname(mainpyfile)

        def script_runner(vimpdb):
            # run target
            vimpdb.runscript(mainpyfile, cont=options.cont)

        header = blue('DEBUG:  ') + cyan(args[0]) + ' ' + ' '.join(args[1:])
        msgs = (header, '', blue('EXECUTION ENDED'))
        run(script_runner, msgs, mainpyfile)

    else:
        testname = args[0]

        # resolve targeted test
        fname, mname, cname = nose.util.split_test_name(testname)
        mname = nose.util.getpackage(fname)  # must be on the path

        # get the module and call
        imp = nose.importer.Importer()
        module = imp.importFromPath(fname, mname)

        load = nose.loader.TestLoader()
        context = load.loadTestsFromName(cname, module)
        test = context._tests.next().test

        if isinstance(test, nose.failure.Failure):
            print red('INVLAID TEST:  ') + cyan(mname + ':') + cname
            raw_input(blue('\nPress any key to continue.'))
            sys.exit(1)  # quit request

        def fcn_runner(vimpdb):
            vimpdb.execRcLines()

            # run setup with thin context and for the test
            vimpdb.runcall_continue(context.setUp)
            vimpdb.runcall_continue(test.setUp)

            try:
                # run target method
                if options.cont:
                    vimpdb.runcall_continue(test.test, *test.arg)

                else:
                    vimpdb.runcall(test.test, *test.arg)

            except:
                raise

            finally:
                # run teardown with automatic continue
                # Be sure it is always run even if there is an exception
                vimpdb.runcall_continue(context.tearDown)
                vimpdb.runcall_continue(test.tearDown)

        header = blue('DEBUG TEST:  ') + cyan(mname + ':') + cname
        msgs = (header, red('TEST FAILED'), green('TEST SUCCEEDED'))
        run(fcn_runner, msgs, fname)


if __name__ == '__main__':
    try:
        main()

    finally:
        # always end the debugging when done
        _send_vim('semicolon#end_debug()')
