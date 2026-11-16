"""Build a CI matrix for each pushed/PR commit and the combined PR merge."""
import json
import os
import subprocess


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def select(event_name, event, repository, sha):
    targets = []
    if event_name == "pull_request":
        pr = event["pull_request"]
        commits = git("rev-list", "--reverse", f"{pr['base']['sha']}..{pr['head']['sha']}").splitlines()
        targets.extend((commit, pr["head"]["repo"]["full_name"], "commit") for commit in commits)
        targets.append((sha, repository, "merge"))
    elif event_name == "push":
        before, after = event["before"], event["after"]
        if before.strip("0"):
            if subprocess.run(["git", "cat-file", "-e", before], capture_output=True).returncode:
                subprocess.run(["git", "fetch", "origin", before], check=True)
            commits = git("rev-list", "--reverse", after, "--not", before).splitlines()
        else:
            base = "refs/remotes/origin/" + event["repository"]["default_branch"]
            exists = subprocess.run(["git", "rev-parse", "--verify", base], capture_output=True).returncode == 0
            commits = git("rev-list", "--reverse", after, *(["--not", base] if exists else [])).splitlines()
        targets.extend((commit, repository, "commit") for commit in commits)
        if not commits:
            targets.append((after, repository, "commit"))
    else:
        targets.append((sha, repository, "commit"))
    include = [{"sha": commit, "repository": repo, "label": f"{kind}-{commit}"}
               for commit, repo, kind in targets]
    if len(include) > 256:
        raise ValueError("More than 256 targets; split the push/PR so every commit can be checked")
    return {"include": include}


if __name__ == "__main__":
    with open(os.environ["GITHUB_EVENT_PATH"]) as stream:
        event = json.load(stream)
    matrix = select(os.environ["GITHUB_EVENT_NAME"], event,
                    os.environ["GITHUB_REPOSITORY"], os.environ["GITHUB_SHA"])
    with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
        stream.write("matrix=" + json.dumps(matrix, separators=(",", ":")) + "\n")
