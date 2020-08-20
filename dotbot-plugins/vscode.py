import os, subprocess, dotbot

class VSCode(dotbot.Plugin):
    '''
    Install VSCode Extensions
    '''

    _directive = 'vscode'
    _insider_directive = 'vscode-insiders'

    def can_handle(self, directive):
        return directive == self._directive or directive == self._insider_directive

    def handle(self, directive, data):
        if directive != self._directive and directive != self._insider_directive:
            raise ValueError('VSCode cannot handle directive %s' % directive)
        return self._process_extensions(data, directive == self._insider_directive)

    def _process_extensions(self, data, isinsiders = False):
        success = True

        executable = 'code-insiders' if isinsiders else 'code'

        with open(os.devnull, 'w') as devnull:
            try:
                subprocess.check_call([executable, '-h'], stdout=devnull, stderr=devnull)
            except (subprocess.CalledProcessError, OSError):
                self._log.error('Visual Studio Code does not appear to be installed')
                return False

            try:
                installed = set(subprocess.check_output([executable, '--list-extensions'], stderr=devnull).split())
            except subprocess.CalledProcessError:
                installed = set()

            for ext in data:
                if ext in installed:
                    self._log.lowinfo('Extension installed %s' % ext)
                    continue

                self._log.lowinfo('Installing extension %s' % ext)

                ret = subprocess.call([executable, '--install-extension', ext], stdout=devnull, stderr=devnull)
                if ret != 0:
                    success = False
                    self._log.warning('Extension %s failed to install' % ext)

            if success:
                self._log.info('All extensions have been installed')
            else:
                self._log.error('Some extensions were not successfully installed')
            return success
