import sys
from nose import run
from nose.plugins.base import Plugin


class NoAnalysis(Plugin):
    ''' Run nosetests in the same manner as normal but do not perform any
    analysis on the results.  Raise exceptions directly without catching in the
    report.
    '''

    score = 0

    def options(self, parser, env):
        print 'aaa'
        parser.add_option('--noanalysis', action='store_true',
                dest='no_analysis', default=False)

    def configure(self, options, conf):
        print 'bbb'
        print options.no_analysis
        self.enabled = options.no_analysis

    def addError(self, test, err):
        print 'ccc'
        return True

    def handleError(self, test, err):
        print 'ddd'
        if self.enabled:
            raise
            return True

    def addFailure(self, test, err):
        print 'eee'
        return True

    def handleFailure(self, test, err):
        print 'fff'
        if self.enabled:
            raise
            return True


if __name__ == '__main__':
    target = sys.argv[1]
    run(argv=['', '--noanalysis', target],
            addplugins=[NoAnalysis()])
