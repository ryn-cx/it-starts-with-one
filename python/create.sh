set -e              # Exit on error
trap deactivate ERR # Deactivate venv on error

read -p "Project Name: " project_name
read -p "Project Description: " project_description
read -p "Project Path: " project_path

# If project_path is empty make the project in the output folder
# This will cause the venv to be invalid, but everything else will work
if [ -z "$project_path" ]; then
    project_path="output/$project_name"
fi

# Display information and ask for confirmation
echo "\nCreating project..."
echo "Project Name: $project_name"
echo "Project Description: $project_description"
echo "Project Path: $project_path"

read -p "Is this correct? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
fi

# Library for working with files and file paths
# /Users/ybr/Developer/common/paved-path

# Remove trailing slash if present
project_path=${project_path%/}

# If the project already exists rename it
if [ -d "$project_path" ]; then
    timestamp=$(date +%Y%m%d%H%M%S)
    mv "$project_path" "${project_path}_$timestamp"
fi

mkdir -p "$project_path"
cp -a files/. "$project_path"
cd "$project_path"
git init

# Create and activate the venv
python -m venv .venv
source .venv/bin/activate

# Install and configure Poetry
pip install poetry
poetry init --quiet --name "$project_name" --license "GNU GPLv3" --description "$project_description"
poetry add --group dev ruff pre-commit pylint pytest

echo "
[tool.ruff]
line-length = 120

[tool.ruff.lint]
select = ["ALL"]
ignore = ["ANN101", "ANN102", "N804"]
# ANN101 - missing-type-self - self doesn't need type hints because the type is known implicitly
# ANN102 - missing-type-cls - cls doesn't need type hints because the type is known implicitly
# N804 - non-pep604-annotation - Sometimes has false positives, and Pylance is more accurate

[tool.ruff.extend-per-file-ignores]
"test_*.py" = ["S101", "INP001"]
# S101 - assert - Assert statements are fine in tests
# INP001 - implicit-namespace-package - Tests are not packages and should not have __init__.py files
" >>pyproject.toml

# Install pre-commit hooks
pre-commit install

# Create a simple readme file
echo "# $project_name" >README.md
echo "$project_description" >>README.md

echo "Setup completed."
