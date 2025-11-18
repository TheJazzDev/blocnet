# Claude Code Configuration

This directory contains configuration files for Claude Code to enhance development workflow for the blocnet Flutter project.

## Contents

### Configuration Files

- **claude.json**: Main configuration file that defines:
  - Project name and description
  - SessionStart hook
  - Files and directories to ignore during analysis

### Hooks

- **hooks/SessionStart.sh**: Automatically runs when a Claude Code session starts to:
  - Check Flutter installation
  - Install/verify project dependencies
  - Run Flutter doctor to verify environment setup

### Slash Commands

Custom commands to streamline common development tasks:

- `/build [platform] [mode]`: Build the app for specified platform (android, ios, web, etc.)
- `/test [file]`: Run all tests or a specific test file
- `/analyze`: Run static analysis to check code quality
- `/run [device]`: Run the app on a specific device or default
- `/clean`: Clean build artifacts and reinstall dependencies

## Usage

These configurations are automatically detected by Claude Code. The SessionStart hook will run automatically when you start a new session, ensuring your environment is ready for development.

Use slash commands by typing them in Claude Code:
```
/analyze
/test
/build android release
```

## Customization

Feel free to modify these files to suit your workflow:
- Add new slash commands in `commands/`
- Modify the SessionStart hook to include additional setup steps
- Update `claude.json` to adjust ignore patterns or other settings
