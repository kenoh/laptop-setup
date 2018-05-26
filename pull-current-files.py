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
        pull_cont = sp.check_output(str(pull_file), shell=True, stderr=sp.PIPE).decode().splitlines(True)
        target_cont = open(target_file).readlines()
        diff = list(difflib.unified_diff(pull_cont, target_cont))
        return diff


    def _do_process(self, cb):
        pull_files = list(pl.Path(self.role, 'files').glob('*.pull'))
        for pull_file in pull_files:
            diff = self._file_changed(pull_file)
            cb(pull_file, diff)


    def examine(self):
        def _examine(pull_file, diff):
            print('## %s: up to date.' % pull_file.name if diff == [] else ''.join(diff))
        return self._do_process(_examine)


    def _do_pull_file(self, pull_file):
        target_file = self._get_target_file_path(pull_file)
        with open(target_file, 'wb') as target_fd:
            pull_rc = sp.run(str(pull_file), shell=True, stdout=target_fd, stderr=sp.PIPE).returncode
        if pull_rc != 0:
            raise Exception('Could not run .pull file. Process returned %d. See above lines for stderr.' % pull_rc)


    def pull(self):
        def _pull(pull_file, diff):
            if diff != []:
                return self._do_pull_file(pull_file)
        return self._do_process(_pull)


@click.command()
@click.option('--force', '-f', is_flag=True, default=False, help='Actually pull the data. Otherwise only examination is performed.')
@click.argument('role', nargs=-1, required=False, type=str)
def main(force, role):
    """Program for getting modified locally deployed files via Ansible roles back to the roles' trees for further availability to the user (usually to be versioned in git, etc.).

    Every script found at `roles/*/files/*.pull` will be run and its standard output (stdout) will be written to the respective (one without the .pull extension) file. You can either specify ROLEs explicitly or leave it blank so that all available roles are processed.

    Simplest example of a .pull script could look like this:
    > #!/bin/sh
    > cat ~/.config/foo.conf
    """
    roles_dir = pl.Path('roles')
    method = Role.pull if force else Role.examine
    roles = [ Role(pl.Path(roles_dir, r)) for r in role ] if role else map(Role, list(roles_dir.iterdir()))
    for role_obj in roles:
        print('# %s' % role_obj)
        method(role_obj)


if __name__ == '__main__':
    main()
