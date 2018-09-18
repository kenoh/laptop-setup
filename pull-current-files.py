#!/usr/bin/env python3
import pathlib as pl
import click
import subprocess as sp
import difflib

class Role():
    def __init__(self, role):
        self.role = role


    def __str__(self):
        return "<Role %s>" % str(self.role)


    def _get_target_file_path(self, pull_file):
        return pl.Path(*pull_file.parts[:-1], pull_file.stem)


    def _file_changed(self, pull_file):
        target_file = self._get_target_file_path(pull_file)
        try:
            new = sp.check_output(str(pull_file), shell=True, stderr=sp.PIPE).decode().splitlines(True)
            old = open(target_file).readlines()
            diff = list(difflib.unified_diff(old, new,
                                             fromfile="a/" + str(target_file),
                                             tofile="b/" + str(target_file)) )
            return diff
        except sp.CalledProcessError as e:
            print("## %s: could not run the .pull file, exception was: " % (pull_file), e)
            return False


    def _do_process(self, cb):
        pull_files = list(pl.Path(self.role, 'files').glob('*.pull'))
        for pull_file in pull_files:
            diff = self._file_changed(pull_file)
            if diff != False:
                cb(pull_file, diff)


    def examine(self):
        def cb(pull_file, diff):
            print('## %s: up to date.' % pull_file.name if diff == [] else ''.join(diff))
        return self._do_process(cb)


    def _do_pull_file(self, pull_file):
        target_file = self._get_target_file_path(pull_file)
        try:
            with open(target_file, 'wb') as target_fd:
                pull_rc = sp.run(str(pull_file), shell=True, stdout=target_fd, stderr=sp.PIPE).returncode
                if pull_rc == 0:
                    print("## %s: changes pulled." % (pull_file))
                    return True
                else:
                    print("## %s: running the .pull file returned unexpected errno %d." % (pull_file, pull_rc))
                    return False
        except sp.CalledProcessError as e:
            print("## %s: could not run the .pull file, exception was: " % (pull_file), e)
            return False
        assert False, "shouldn't have gotten here"


    def pull(self):
        def cb(pull_file, diff):
            if diff != []:
                return self._do_pull_file(pull_file)
        return self._do_process(cb)


    def _do_write_diff_file(self, pull_file, diff):
        target_file = pull_file.with_suffix(".pull.diff")
        with open(target_file, 'wb') as fd:
            fd.write("".join(diff).encode())
            print("## %s: diff file written in %s." % (pull_file, target_file))
        return True


    def write_diffs(self):
        def cb(pull_file, diff):
            if diff != []:
                return self._do_write_diff_file(pull_file, diff)
        return self._do_process(cb)


METHODS = {'overwrite': Role.pull, 'write-diffs': Role.write_diffs, 'examine': Role.examine }
@click.command()
@click.argument('method', required=False, type=click.Choice(METHODS.keys()), default='examine')
@click.argument('role', nargs=-1, required=False, type=str)
def main(method, role):
    """Program for getting modified locally deployed files via Ansible roles back to the roles' trees for further availability to the user (usually to be versioned in git, etc.).

    Every script found at `roles/*/files/*.pull` will be run and its standard output (stdout) will be written to the respective (one without the .pull extension) file. You can either specify ROLEs explicitly or leave it blank so that all available roles are processed.

    Simplest example of a .pull script could look like this:
    > #!/bin/sh
    > cat ~/.config/foo.conf
    """
    method = METHODS[method]
    roles_dir = pl.Path('roles')
    roles = [ Role(pl.Path(roles_dir, r)) for r in role ] if role else map(Role, list(roles_dir.iterdir()))
    for role_obj in roles:
        print('# %s' % role_obj)
        method(role_obj)


if __name__ == '__main__':
    main()
