from thefuck.utils import for_app


@for_app('grep')
def match(command):
    return 'no such file or directory' in command.stderr.lower()


def get_new_command(command):
    parts = command.script.split()
    return 'grep {} {}'.format(parts[2], parts[1])

