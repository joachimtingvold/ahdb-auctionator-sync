"""Validate PR release labels and tag tested merges."""

from datetime import datetime
import json
import os
import re
import subprocess
import sys
from zoneinfo import ZoneInfo


RELEASE_LABELS = {'release:stable', 'release:beta', 'release:none'}
VERSION = re.compile(r'(\d{4}\.\d{2}\.\d{2})\.(0[1-9]|[1-9][0-9])(?:-beta)?')
OSLO = ZoneInfo('Europe/Oslo')


def release_labels(labels):
    return RELEASE_LABELS.intersection(labels)


def release_selection(labels):
    selected = release_labels(labels)
    if len(selected) != 1:
        found = ', '.join(sorted(selected)) or 'none'
        raise ValueError(
            'Select exactly one of release:stable, release:beta, or release:none. '
            f'Found: {found}.')
    return selected.pop()


def dated_tag_for_commit(tags, sha):
    return next((name for name, target in tags.items()
                 if target == sha and VERSION.fullmatch(name)), None)


def next_tag(tags, sha, selection, now):
    """Return the next version, or None if this commit needs no new tag."""
    if selection == 'release:none' or dated_tag_for_commit(tags, sha):
        return None

    date = now.astimezone(OSLO).strftime('%Y.%m.%d')
    latest = 0
    for tag in tags:
        match = VERSION.fullmatch(tag)
        if match and match[1] == date:
            latest = max(latest, int(match[2]))

    if latest == 99:
        raise ValueError(f'All 99 release numbers for {date} (Europe/Oslo) are exhausted.')
    suffix = '-beta' if selection == 'release:beta' else ''
    return f'{date}.{latest + 1:02d}{suffix}'


def pr_labels(repo, number):
    response = subprocess.check_output(['gh', 'api', f'repos/{repo}/pulls/{number}'])
    return {label['name'] for label in json.loads(response)['labels']}


def validate(repo, number, action):
    labels = pr_labels(repo, number)
    if action == 'opened' and not release_labels(labels):
        # Add only the default. Keep other labels if a maintainer edits them concurrently.
        subprocess.check_output([
            'gh', 'api', '--method', 'POST', f'repos/{repo}/issues/{number}/labels',
            '-f', 'labels[]=release:stable',
        ])
        # GITHUB_TOKEN label changes may not start another workflow run.
        labels = pr_labels(repo, number)
    print(f'Selected {release_selection(labels)}.')


def remote_tags():
    refs = subprocess.check_output(['git', 'ls-remote', '--tags', 'origin'], text=True)
    tags = {}
    for line in refs.splitlines():
        sha, ref = line.split('\t')
        name = ref.removeprefix('refs/tags/')
        if not name.endswith('^{}'):
            tags.setdefault(name, sha)
        else:
            # A peeled annotated tag points to the tagged commit.
            tags[name.removesuffix('^{}')] = sha
    return tags


def tag_merge(repo, number, sha):
    selection = release_selection(pr_labels(repo, number))
    if selection == 'release:none':
        print('Selected release:none. Skipping the tag.')
        return

    tags = remote_tags()
    tag = next_tag(tags, sha, selection, datetime.now(OSLO))
    if tag is None:
        existing = dated_tag_for_commit(tags, sha)
        print(f'{sha} already has release tag {existing}.')
        return existing

    subprocess.run(['git', 'push', 'origin', f'{sha}:refs/tags/{tag}'], check=True)
    print(f'Pushed {tag} for {sha}.')
    return tag


def existing_tag(tag, main):
    if not VERSION.fullmatch(tag):
        raise ValueError(f'Expected a dated release tag, got {tag!r}.')
    sha = remote_tags().get(tag)
    if sha is None:
        raise ValueError(f'Release tag {tag} does not exist on origin.')
    subprocess.run(['git', 'merge-base', '--is-ancestor', sha, main], check=True)
    return tag


if __name__ == '__main__':
    operation, value, argument = sys.argv[1:]
    try:
        if operation == 'validate':
            validate(os.environ['GITHUB_REPOSITORY'], value, argument)
        elif operation == 'tag':
            tag = tag_merge(os.environ['GITHUB_REPOSITORY'], value, argument)
        elif operation == 'existing-tag':
            tag = existing_tag(value, argument)
        else:
            raise ValueError(f'Unknown operation: {operation}')
        if operation != 'validate' and tag:
            with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
                print(f'tag={tag}', file=output)
    except (subprocess.CalledProcessError, ValueError) as error:
        sys.exit(str(error))
