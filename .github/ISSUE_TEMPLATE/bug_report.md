---
name: Bug report
about: Create a report to help us improve
title: "[BUG] {title}"
labels: bug
assignees: ''

---

**Desktop (please complete the following information):**
 - OS: [e.g. ArchLinux or Ubuntu]
 - Version of Plasma Framework

**Describe the bug**
A clear and concise description of what the bug is.

**Any error message shown in the console**
Please execute the following commands in the console and upload the outputs.

git clone https://github.com/rbn42/panon.git
cd panon
git submodule update --init
# You need to install plasma-sdk to get plasmoidviewer.
plasmoidviewer --applet ./plasmoid/
