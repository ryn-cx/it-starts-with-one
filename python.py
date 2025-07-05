"""Python project setup script."""

import logging
import shutil
import subprocess
import urllib.request
from pathlib import Path
from typing import IO, Any

from pydantic import Field
from pydantic_settings import BaseSettings

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter("%(message)s"))
logger.addHandler(handler)


class PythonProject(BaseSettings, cli_parse_args=True, cli_enforce_required=True):
    """Python project setup class."""

    name: str = Field(description="Name of the project")
    description: str | None = Field(
        default=None,
        description="Description of the project (optional)",
    )
    parent_path: Path = Field(
        default=Path("~/Developer").expanduser(),
        description="Path to the folder that will contain the project (optional)",
    )
    type: str = Field(
        default="app",
        description="Type of the project (app, package, or library)",
        json_schema_extra={"choices": ["app", "package", "library"]},
    )

    def _underscored_name(self) -> str:
        return self.name.replace(" ", "_").lower()

    def _dashed_name(self) -> str:
        return self.name.replace(" ", "-").lower()

    def _project_path(self) -> Path:
        return self.parent_path / self._dashed_name()

    def _files_path(self) -> Path:
        return Path(__file__).parent / "files"

    def _pyproject_toml_path(self) -> Path:
        return self._project_path() / "pyproject.toml"

    def _append_to_file(
        self,
        file_path: Path,
        content: str,
    ) -> None:
        with file_path.open("a") as file:
            file.write(f"\n{content}")

    def _run(
        self,
        command: list[str | Path] | list[str],
        stdout: int | IO[Any] | None = subprocess.DEVNULL,
        stderr: int | IO[Any] | None = subprocess.DEVNULL,
        cwd: Path | str | None = None,
        *,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        """subprocess.run with modified default values.

        By default the process will run silently, the exit code will be checked,
        and stdout and stderr will be formatted as strings.

        Args:
            command: The command to run as a list of strings or Path objects.
            stdout: Where to send standard output.
            stderr: Where to send standard error.
            cwd: The working directory to run the command in.
            check: Whether to raise an error if the command fails.

        Returns:
            subprocess.CompletedProcess: The result of the command execution.

        """
        try:
            return subprocess.run(
                [str(value) for value in command],
                check=check,
                stdout=stdout,
                stderr=stderr,
                cwd=cwd or self._project_path(),
                text=True,
            )
        except subprocess.CalledProcessError as e:
            if e.stdout:
                logger.info("Standard output: %s", e.stdout)
            if e.stderr:
                logger.info("Standard error: %s", e.stderr)
            raise

    def create_project_folder(self) -> None:
        """Create the project folder."""
        logger.info("Creating project folder")
        self._project_path().mkdir(parents=True, exist_ok=True)

    def add_dependencies(self, dependencies: list[str]) -> None:
        """Add dependencies to the project."""
        self._run(["uv", "add", *dependencies])

    def add_dev_dependencies(self, dependencies: list[str]) -> None:
        """Add development dependencies to the project."""
        self._run(["uv", "add", "--dev", *dependencies])

    def initialize_git(self) -> None:
        """Initialize a git repository."""
        logger.info("Initializing git")
        command = ["git", "init"]
        self._run(command)

    def initialize_uv(self) -> None:
        """Initialize uv."""
        logger.info("Initializing uv")
        command = [
            "uv",
            "init",
            self._dashed_name(),
            "--author-from",
            "git",
        ]

        if self.type:
            command += [f"--{self.type}"]
        if self.description:
            command += ["--description", self.description]

        self._run(command, cwd=self._project_path().parent)

    def install_development_dependencies(self) -> None:
        """Install development dependencies."""
        logger.info("Installing development dependencies")
        self.add_dev_dependencies(["ruff", "pylint", "pre-commit", "pytest"])

    def configure_precommit(self) -> None:
        """Create pre-commit.yaml, update it, and install it."""
        logger.info("Configuring pre-commit")
        pre_commit_template_path = self._files_path() / ".pre-commit-config.yaml"
        pre_commit_path = self._project_path() / ".pre-commit-config.yaml"
        shutil.copyfile(pre_commit_template_path, pre_commit_path)

        # Update all of the hooks to the latest version because the template is based on
        # whatever version was the newest when the template was created.
        self._run(["uv", "run", "pre-commit", "install"])
        self._run(["uv", "run", "pre-commit", "autoupdate"])

    def create_gitignore(self) -> None:
        """Create .gitignore.

        Download the official Python .gitignore file from GitHub and add additional
        custom rules.
        """
        logger.info("Creating .gitignore")

        url = "https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore"
        with urllib.request.urlopen(url) as response:
            gitignore_config = response.read().decode("utf-8")

        gitignore_config = "# Mac OS\n.DS_Store\n\n" + gitignore_config

        (self._project_path() / ".gitignore").write_text(gitignore_config)

    def configure_ruff(self) -> None:
        """Update pyproject.toml with ruff configurations."""
        logger.info("Configuring ruff")
        ruff_config_path = self._files_path() / "ruff.toml"
        ruff_config_string = ruff_config_path.read_text()
        self._append_to_file(self._pyproject_toml_path(), ruff_config_string)

    def update_readme(self) -> None:
        """Update README.md."""
        logger.info("Updating README.md")
        readme_text = f"# {self.name}\n"
        if self.description:
            readme_text += f"{self.description}\n"
        (self._project_path() / "README.md").write_text(readme_text)


if __name__ == "__main__":
    # Settings automatically gets arguments from sys.argv so the error can be
    # ignored.
    settings = PythonProject()  # type: ignore[call-arg]
    settings.initialize_uv()
    settings.initialize_git()  # Relies on initialize_uv
    settings.create_gitignore()  # Relies on initialize_uv
    settings.install_development_dependencies()  # Relies on initialize_uv
    settings.configure_precommit()  # Relies on install_development_dependencies
    settings.configure_ruff()  # Relies on initialize_uv
    settings.update_readme()  # Relies on create_project_folder
