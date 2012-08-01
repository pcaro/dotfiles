#!/usr/bin/env python
from glob import glob
from os import chdir, environ, makedirs, symlink, walk
from os.path import dirname, exists, expanduser, islink, join, realpath, relpath
from sys import stderr


REPO = environ.get('DOTFILES_REPO', expanduser('~/.dotfiles'))
HOME = environ['HOME']
EXCLUDED_DIRS = ['.hg', '.git', '.svn']
IGNORED = ['dotfile-link', 'README']
chdir(REPO)


def expand_ignored():
    ignore_globs = []
    try:
        fh = open(join(REPO, '.dfignore'))
        for expr in fh.readlines():
            expr = expr.strip()
            if expr and not expr.startswith('#'):
                ignore_globs.append(expr)
        fh.close()
    except IOError:
        pass
    for expr in ignore_globs:
        IGNORED.extend(glob(expr))


def managed():
    for dirpath, dirs, filenames in walk(REPO):
        for dir in EXCLUDED_DIRS:
            if dir in dirs:
                print >> stderr, "* skipping: %s/%s " % (dirpath, dir)
                dirs.remove(dir)
        relative_path = relpath(dirpath, REPO)
        for fn in filenames:
            full_path = join(relative_path, fn).lstrip('./')
            if any(full_path.startswith(i) for i in IGNORED):
                continue

            target = ("~/.%s" % full_path)
            yield join(REPO, full_path), expanduser(target)


expand_ignored()

print "Updating %s dotfiles from %s" % (HOME, REPO)
stats = dict(noop=0, new=0, error=0, newdir=0)
for source, target in managed():
    if islink(target):
        dest = realpath(target)
        if dest != source:
            print >> stderr, "* skipping: %s is a symlink to %s" (target, dest)
            stats['error'] += 1
        else:
            stats['noop'] += 1
        continue
    elif exists(target):
        print >> stderr, "* skipping: %s already exists" % (target,)
        stats['error'] += 1
        continue
    else:
        directory = dirname(target)
        if not exists(directory):
            makedirs(directory)
            stats['newdir'] += 1
        print "- linking %s -> %s" % (target, source)
        symlink(source, target)
        stats['new'] += 1

print ("%(noop)s unchanged, %(new)s new links, "
       "%(newdir)s directories created, %(error)s errors." % stats)
