#!/bin/sh

cd "$CLAUDE_PROJECT_DIR"
agent_files=$(find . -name "AGENTS.md" -type f)
[ -z "$agent_files" ] && exit 0

cat <<end_context
<agentsmd_instructions>
This project uses AGENTS.md files to provide scoped instructions based on the
file or directory being worked on.

This project has the following AGENTS.md files:

<available_agentsmd_files>
$agent_files
</available_agentsmd_files>

NON-NEGOTIABLE: When working with any file or directory within the project:

1. Load ALL AGENTS.md files in the directory hierarchy matching that location.
   You do not have to reload AGENTS.md files you have already loaded previously.

2. ALWAYS apply instructions from the AGENTS.md files that match that location.
   When there are conflicting instructions, apply instructions from the
   AGENTS.md file that is CLOSEST (most specific) to that location. More
   specific instructions OVERRIDE more general ones.

   <example>
     Project structure:
       AGENTS.md
       subfolder/
         file.txt
         AGENTS.md

     When working with "subfolder/file.txt":
       - Instructions from "subfolder/AGENTS.md" take precedence
       - Instructions from root "AGENTS.md" apply only if not overridden
   </example>

3. If there is a root ./AGENTS.md file, ALWAYS apply its instructions to ALL
   work within the project, as everything you do is within scope of the project.
   Precedence rules still apply for conflicting instructions.
</agentsmd_instructions>
end_context

# If there is a root AGENTS.md, load it now because it always applies.
if [ -f "./AGENTS.md" ]; then
	cat <<-end_root_context
		The content of ./AGENTS.md is as follows:
		<root_agentsmd>
		$(cat "./AGENTS.md")
		</root_agentsmd>
	end_root_context
fi
