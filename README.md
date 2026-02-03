
This tool provides consistent SQL linting and auto-fixing using `SQLFluff`.

### Setup

Requirements: Python 3.9+

#### Quick Setup (Recommended)

From the repository root, run:
```
.\setup.ps1
```

To force clean rebuild of the environment:
```
.\setup.ps1 -Force
```

#### Manual Setup

1. Open `sql-lint-tool` folder in terminal and run:
```
python -m venv .venv
.\.venv\Scripts\activate.ps1
pip install -r requirements.txt
```

2. To setup custom rules run:
```
cd custom-rules
pip install -e .
```

### How to run the Linter

#### Use script

All commands are executed **from the root of your solution**.

For a file:
```
.\sql-lint-tool\run.ps1 lint "$FilePath"
.\sql-lint-tool\run.ps1 fix "$FilePath"
```

For a folder:
```
.\sql-lint-tool\run.ps1 lint "Path\To\Folder"
.\sql-lint-tool\run.ps1 fix "Path\To\Folder"
```

For entire solution
```
.\sql-lint-tool\run.ps1 lint
.\sql-lint-tool\run.ps1 fix
```

#### Setup External Tools (Rider only)

1. Go to `File -> Settings -> Tools -> External Tools`
2. Click `+` button to add a new tool
3. Name: "SQL Lint" / "SQL Fix"
4. Program: powershell
5. Arguments:
	For lint:
		-NoProfile -ExecutionPolicy Bypass -File "$ProjectFileDir$\sql-lint-tool\run.ps1" lint "$FilePath$" 
	For Fix:
		-NoProfile -ExecutionPolicy Bypass -File "$ProjectFileDir$\sql-lint-tool\run.ps1" fix "$FilePath$" 
6. Click `Ok`
7. Now you can run these tools from `Tools -> External Tools -> SQL Lint / SQL Fix`

#### Create shortcuts for external tools

1. Go to `File -> Settings -> Keymap -> External Tools`
2. Setup shortcut for each external tool
