# Ubuntu Fastest Mirror

![ubuntu fastest mirror preview in terminal](/assets/preview.gif)

## Introduction

The Ubuntu Mirror Selection Script is a Bash script designed to help you find and select the fastest Ubuntu mirrors based on specified country codes or geographic locations. The script supports both traditional Ubuntu (pre-24.04) with `sources.list` and the newer Ubuntu 24.04+ that uses the `ubuntu.sources` format in the `sources.list.d` directory.

## Prerequisites

- This script works on Ubuntu systems. Requires `wget` and `bc`.
- Ensure you have the necessary permissions to run the script, especially if you intend to modify system files.
- For Ubuntu 24.04+, this script will modify the `ubuntu.sources` file in `/etc/apt/sources.list.d/`.
- For older Ubuntu versions, this script will modify the traditional `/etc/apt/sources.list` file.

## Data Units Used in This Tool

To avoid confusion, here are the data units used in this script:

- **KB (Kilobytes)**: Used for file sizes (1 KB = 1024 bytes)
- **Kbps (Kilobits per second)**: Used for network speeds (1 Kbps = 1000 bits per second)
- **Mbps (Megabits per second)**: Used for higher network speeds (1 Mbps = 1000 Kbps)
- **Gbps (Gigabits per second)**: Used for very high network speeds (1 Gbps = 1000 Mbps)

Note: When specifying the test size with `-s` option, the value is in KB (Kilobytes), but mirror speeds are shown in bits per second (bps, Kbps, Mbps, or Gbps), which is the standard for network transfer rates.

## Obtaining the Script

You can obtain the Ubuntu Mirror Selection Script by either downloading it directly from the provided link or by cloning the repository from GitHub:

- **Download from GitHub**: [Download Script](https://raw.githubusercontent.com/ijash/ubuntu-fastest-mirror/master/run.sh) or

  ```bash
  curl -O https://raw.githubusercontent.com/ijash/ubuntu-fastest-mirror/master/run.sh
  ```

  This will download the script directly to your current directory.

- **Clone Repository**: If you prefer to clone the entire repository, you can do so using the following command:  
  HTTPS:
  ```bash
  git clone https://github.com/ijash/ubuntu-fastest-mirror.git
  ```
  or SSH:
  ```
  git clone git@github.com:ijash/ubuntu-fastest-mirror.git
  ```

## Getting Started (Preparation)

1. **Downloaded Script**: If you downloaded the script directly, ensure it has executable permissions. You can do this using the following command in your terminal:

   ```bash
   chmod +x run.sh
   ```

2. **Cloned Repository**: If you cloned the repository, navigate to the repository directory:
   ```bash
   cd ubuntu-fastest-mirror
   chmod +x run.sh
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

   To automatically fill in the region based on your IP you can use `./run.sh -c $(curl -s https://ipinfo.io/json | jq -r '.country')` (requires `jq` to be installed).

3. **Automatic Selection**: To automatically select the fastest mirror without user prompt and backup the sources files, you can use the `-a` or `--auto` option:

   ```bash
   ./run.sh -a
   ```

4. **Backup Sources Files**: If you want to backup your apt sources configuration before making changes, use the `-b` or `--backup` option:

   ```bash
   ./run.sh -b
   ```

   For Ubuntu 24.04+, this will backup the `ubuntu.sources` file in `/etc/apt/sources.list.d/`.
   For older Ubuntu versions, this will backup the traditional `/etc/apt/sources.list` file.

5. **Set Test Size**: To customize the size of the data used for testing mirror speed, use the `-s` or `--size` option followed by a size in KB (Kilobytes). The default is 100KB:

   ```bash
   ./run.sh -s 500
   ```

   This sets the test size to 500KB, which can provide more accurate speed measurements for faster connections.

6. **Force Legacy Mode**: To force the script to use the legacy method (updating sources.list) even on Ubuntu 24.04+ or when version detection fails, use the `-L` or `--legacy` option:

   ```bash
   ./run.sh -L -c US
   ```

   This can be useful if you prefer to use the traditional sources.list format on newer Ubuntu versions.

7. **Default Behavior**: If no options are provided, the script defaults to using mirrors from http://mirrors.ubuntu.com/mirrors.txt.

## Example Usage

- Retrieve mirrors from Indonesia and automatically select the fastest mirror:

  ```bash
  ./run.sh -a -c ID
  ```

- Backup the current sources files and select the fastest mirrors from the United States and Japan:

  ```bash
  ./run.sh -b -c US JP
  ```

- Test with a larger sample size (500KB) for more accurate results on fast connections:

  ```bash
  ./run.sh -s 500 -c US
  ```

- Automatically select the fastest mirror with a smaller test size (50KB) for slow connections:

  ```bash
  ./run.sh -a -s 50
  ```

- Force legacy format for sources management:

  ```bash
  ./run.sh -L -c US JP
  ```

- Combine multiple options for a customized experience:

  ```bash
  ./run.sh -b -c JP US -s 200 -L
  ```

  This backs up your sources files, tests mirrors from Japan and the US with a 200KB sample size, and uses the legacy sources.list format.
