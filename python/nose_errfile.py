"""
vim-semicolon

https://github.com/tobinvanpelt/vim-semicolon.git

Sends error and failure results to an error file.

This module was extended from https://github.com/nvie/nose-machineout

Copyright (c) Tobin Van Pelt. Distributed under the same terms as Vim itself.
See :help license.

"""

import os
import traceback
import sys

try:
    import nose
    from nose.plugins import Plugin

except Exception, e:
    print e
    print "The current environment does not have 'nose' installed."
    print "\nTo install 'nose' use:"
    print "\n   > pip install nose"

    sys.exit(0)


class ErrorStreamer(Plugin):
    """
    Output errors and failures to a seperate file.
    """

    def options(self, parser, env):
        super(ErrorStreamer, self).options(parser, env)

        parser.add_option('--errfile', dest='err_file', default=None,
                help='the name of the error file to write errors to')

    def configure(self, options, conf):
        super(ErrorStreamer, self).configure(options, conf)

        if options.err_file is not None:
            self._err_file = options.err_file
            self._testpath = options.where[0]

            self.enabled = True

    def begin(self):
        self._err_stream = open(self._err_file, 'w')
        self._basepath = os.getcwd()

    def beforeDirectory(self, path):
        self._testpath = path

    def beforeImport(self, filename, module):
        self._module = module

    def finalize(self, result):
        self._err_stream.close()

    def addError(self, test, err):
        self._stderr(err, 'ERROR')

    def addFailure(self, test, err):
        self._stderr(err, 'FAILURE')

    def _get_score(self, frame):
        # score the frame
        fname, _, funname, _ = frame

        score = 0.0
        max_score = 7.0  # update this when new conditions are added

        # Being in the project directory means it's one of our own files
        if fname.startswith(self._testpath):
            score += 4

        # Being one of our tests means it's a better match
        if os.path.basename(fname).find('test') >= 0:
            score += 2

        # The check for the `assert' prefix allows the user to extend
        # unittest.TestCase with custom assert-methods, while
        # machineout still returns the most useful error line number.
        if not funname.startswith('assert'):
            score += 1

        return score / max_score

    def _get_best_frame(self, traceback):
        best_score = 0
        best = traceback[-1]   # fallback value

        for frame in traceback:
            curr_score = self._get_score(frame)
            if curr_score > best_score:
                best = frame
                best_score = curr_score

                # Terminate the walk as soon as possible
                if best_score >= 1:
                    break
        return best

    def _stderr(self, err, errtype):
        etype, value, tb = err
        fulltb = traceback.extract_tb(tb)
        fname, lineno, funname, line = self._get_best_frame(fulltb)
        fname = os.path.relpath(fname, self._basepath)

        location = '%s.%s' % (self._module, funname)

        msg = '%s ... %s    %s: %s' % (location, errtype,
                etype.__name__, value.message)
        errline = '%s:%d: %s' % (fname, lineno, msg)
        self._err_stream.write(errline + '\n')


if __name__ == '__main__':
    # used to run nosetests with plugin active
    nose.run(addplugins=[ErrorStreamer()])
