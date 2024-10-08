# Dynamically find the python folder in the .venv folder
folder_path=$(realpath .venv/lib/python*)

# Get the path for root.pth which will be created to modify the PYTHONPATH
root_path="$folder_path/site-packages/root.pth"

# Add the root folder of the project to root_path so importing is simplified
echo "../../../.." > $root_path
