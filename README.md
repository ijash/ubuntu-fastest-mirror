# Ubuntu Fastest Mirror
## Introduction
The Ubuntu Mirror Selection Script is a Bash script designed to help you find and select the fastest Ubuntu mirrors based on specified country codes or geographic locations.

## Prerequisites
- This script requires a Unix-like environment, such as Linux or macOS.
- You need to have Bash installed on your system.
- Ensure you have the necessary permissions to run the script, especially if you intend to modify system files.

## Obtaining the Script
You can obtain the Ubuntu Mirror Selection Script by either downloading it directly from the provided link or by cloning the repository from GitHub:

- **Download from GitHub**: [Download Script](https://raw.githubusercontent.com/ijash/ubuntu-fastest-mirror/master/run.sh)
  
- **Clone Repository**: If you prefer to clone the entire repository, you can do so using the following command:  
  HTTPS:
  ```bash
  git clone https://github.com/ijash/ubuntu-fastest-mirror.git
  ```
  or SSH:
  ```
  git clone git@github.com:ijash/ubuntu-fastest-mirror.git
  ```

## Getting Started
1. **Downloaded Script**: If you downloaded the script directly, ensure it has executable permissions. You can do this using the following command in your terminal:
   ```bash
   chmod +x run.sh
   ```

2. **Cloned Repository**: If you cloned the repository, navigate to the repository directory:
   ```bash
   cd ubuntu-fastest-mirror
   ```

## Usage
To use the script, follow these steps:

1. **Display Help Information**: If you're unsure about how to use the script or what options are available, you can display the help message by running:
   ```bash
   ./run.sh -h
   ```
   This will provide you with a summary of available options, examples, and usage instructions.

2. **Retrieve Mirrors**: You can retrieve mirrors based on [country codes available](http://mirrors.ubuntu.com/) using the `-c` or `--country` option. For example:
   ```bash
   ./run.sh -c US JP ID
   ```
   This command retrieves mirrors from the United States (US), Japan (JP), and Indonesia (ID).

3. **Automatic Selection**: To automatically select the fastest mirror without user prompt and backup the sources.list file, you can use the `-a` or `--auto` option:
   ```bash
   ./run.sh -a
   ```

4. **Backup Sources.List**: If you want to backup the current `sources.list` file before making changes, use the `-b` or `--backup` option:
   ```bash
   ./run.sh -b
   ```

5. **Default Behavior**: If no options are provided, the script defaults to using mirrors from http://mirrors.ubuntu.com/mirrors.txt.

## Example Usage
- Retrieve mirrors from Indonesia and automatically select the fastest mirror:
  ```bash
  ./run.sh -a -c ID
  ```

- Backup the current sources.list file and select the fastest mirrors from the United States and Japan:
  ```bash
  ./run.sh -b -c US JP
  ```
