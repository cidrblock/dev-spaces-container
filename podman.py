import os
import shlex
COMMAND = "podman run --rm --tty --interactive -v /projects/dev-spaces-container/:/projects/dev-spaces-container/ --workdir /projects/dev-spaces-container --group-add=root --ipc=host -v /tmp/ansible-navigator_0tr0xo21/artifacts/:/runner/artifacts/:Z -v /tmp/ansible-navigator_0tr0xo21/:/runner/:Z --env-file /tmp/ansible-navigator_0tr0xo21/artifacts/2977aa59-6675-46cf-9278-c726d26d170c/env.list --quiet --name ansible_runner_2977aa59-6675-46cf-9278-c726d26d170c --user=root ghcr.io/ansible/creator-ee:v0.22.0 ansible-playbook /projects/dev-spaces-container/site.yml"

parts = shlex.split(COMMAND)
parts.remove("--interactive")


os.execvp(parts[0], parts)

