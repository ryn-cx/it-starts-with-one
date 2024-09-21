pdm init --license AGPL-3.0-or-later
pdm add -d ruff pylint pre-commit pytest pylint-pytest pytest-cov

# Configure ruff.
cat <<EOL >>"pyproject.toml"
# Configure ruff
[tool.ruff.lint]
select = ["ALL"]
ignore = ["ANN101", "ANN102", "TD002", "TD003"]
# ANN101: missing-type-self - Deprecated rule that is redundant. It requires
# explicit type hints on self which is not required because the type can always
# be inferred.

# ANN102: missing-type-cls - Deprecated rule that is redundant. It requires
# explicit type hints on cls which is not required because the type can always
# be inferred.

# TD002: missing-todo-author - This rule requires that a specific author is
# listed for TODO comments which is pointless because the author is always me.

# TD003: missing-todo-link - This rule requires that a specific issue link is
# listed for TODO comments, this is pointless because the TODO statements are
# the reminder to create the issue in the first place. If an issue link exists
# then the TODO comment would not exist.

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.per-file-ignores]
"tests/*.py" = ["D101", "D102", "D104", "S101"]
# D101: undocumented-public-class - Tests do not need docstrings
# D102: undocumented-public-method - Tests do not need docstrings
# D104: undocumented-public-package - Tests do not need docstrings
# S101: assert - Using asserts in tests should be allowed
EOL

# Create pre-commit config.
cat >.pre-commit-config.yaml <<EOL
repos:
  - repo: "https://github.com/pre-commit/pre-commit-hooks"
    rev: v4.4.0
    hooks:
      # General hooks
      - id: trailing-whitespace # Clean up trailing whitespace

      # Python hooks
      - id: check-ast # Make sure Python files are valid
      - id: check-builtin-literals # Only allow literals when creating empty data structures
      - id: check-docstring-first # Make sure docstrings are in the correct location

      # TOML hooks, useful for checking pyproject.toml
      - id: check-toml # Validate pyproject.toml and other toml files

      # YAML hooks
      - id: check-yaml #Validate .pre-commit-config.yaml and other yaml files
      - id: sort-simple-yaml # Clean up .pre-commit-config.yaml and other yaml files

      # Compatibility hooks
      - id: check-case-conflict # Make sure files are safe for Windows
      - id: end-of-file-fixer # Make sure files end in a newline
      - id: mixed-line-ending # Clean up line endings to all be the same
      - id: fix-byte-order-marker # Remove UTF-8 byte order marker

  # Format and lint Python code
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.8
    hooks:
      # Run the formatter.
      - id: ruff-format
EOL

# Configure tests for VSCode.
mkdir -p .vscode
cat <<EOL > .vscode/settings.json
{
    "python.testing.pytestArgs": [
        "tests",
        "--cov",
        "--cov-report=xml"
    ],
    "python.testing.unittestEnabled": false,
    "python.testing.pytestEnabled": true
}
EOL

# pre-commit versions are hard coded into the file, update them so they will
# always be the newest version when making a new project.
./.venv/bin/pre-commit autoupdate

# Configure pylint.
cat >.pylintrc <<EOL
[MASTER]
; Official plugin for using pylint with pytest
load-plugins=pylint_pytest

[MESSAGES CONTROL]
disable=C0115, C0116, C0301
; C0115: missing-class-docstring - Ruff makes this redundant
; C0116: missing-function-docstring - Ruff makes this redundant
; C0301: line-too-long - Ruff makes this redundant
EOL

# Prepend .gitignore to include .DS_Store: https://stackoverflow.com/a/10587853
sed -i.old '1s;^;# Mac OS\n.DS_Store\n\n;' .gitignore
rm .gitignore.old

# Dynamically find the main folder for the project in src
folder_path=$(realpath src/*)

# Create the py.typed file so type hints are used if the project is imported.
touch "$folder_path/py.typed"
