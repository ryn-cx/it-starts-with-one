set -e              # Exit on error
trap deactivate ERR # Deactivate venv on error

project_name=$1

if [ -z "$project_name" ]; then
    echo "No project name provided. Usage: ./create.sh <project_name>"
    exit 1
fi

# Check if directory exists and delete it
if [ -d "output/$project_name" ]; then
    rm -rf "output/$project_name"
fi

mkdir -p "output/$project_name"
cp -a files/. "output/$project_name"
cd "output/$project_name"
git init

# Create and activate the venv
python -m venv .venv
source .venv/bin/activate

# Install and configure Poetry
pip install poetry
poetry init --quiet --name "$project_name" --license "GNU GPLv3"
poetry add --group dev ruff pre-commit pylint flake8 pytest

# Install pre-commit hooks
pre-commit install

echo "Setup completed."
