## Hardlinked Files — Check Before Editing

Makefiles, `*.env` files and shared scripts such as `git-release` are often hardlinked across repos. Before editing one, run `stat -f "%l %N" <file>`. If the link count is above 1, warn the user and never use Edit, Write or `sed -i` — on macOS all three replace the inode and silently break the chain. Edit in place with `sed '…' file > tmp && cat tmp > file`, then rerun `stat` to confirm the count held.

