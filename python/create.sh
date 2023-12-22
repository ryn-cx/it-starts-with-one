set -e              # Exit on error
trap deactivate ERR # Deactivate venv on error

read -p "Project Name: " project_name
read -p "Project Description: " project_description
read -p "Project Path: " project_path

# Display information and ask for confirmation
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
poetry add --group dev ruff pre-commit pylint flake8 pytest

# Install pre-commit hooks
pre-commit install

# Create a simple readme file
echo "# $project_name" >README.md
echo "$project_description" >>README.md

echo "Setup completed."
