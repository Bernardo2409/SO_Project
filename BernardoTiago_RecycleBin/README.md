# Linux Recycle Bin System 
 
## Author 

Bernardo Mota Coelho 
125059

Tiago Francisco Crespo do Vale
125913
 
## Description 
Our project consists in a Linux Recycle Bin Simulation. It aims to replicate the tradition Recycle Bin, but in a command-line environment using the terminal. 
The system allows the user to delete files, list them and recover to his original location.

 
## Installation 
 
If repository is online and public: 

- type on terminal: git clone https://github.com/Bernardo2409/SO_Project 

- type on terminal: cd BernardoTiago_RecycleBin

If repository is in .rar or .zip:

- download the files, unzip and type on terminal: cd BernardoTiago_RecycleBin


## Usage 


chmod +x recycle_bin.sh

./recycle_bin.sh <comand> <options>

Examples:
    -- ./recycle_bin.sh init
    -- echo "content" > file1.txt"
    -- ./recycle_bin.sh delete file1.txt
    -- ./recyle_bin.sh list
    -- ./recycle_bin.sh restore file1.txt

 
 
## Features 

- Safe deletion of files — prevents permanent data loss.

- Restore deleted files by name or ID.

- Metadata tracking (file name, original path, deletion date, size, owner, permissions).

- Simple and detailed list views (list and list --detailed).

- Search function for locating deleted files quickly (flag -i to search with ignore case).

- Option to permanently empty the bin (empty / empty --force).

- Automatic creation of the Recycle Bin directory and configuration file.

- Integrated logging system that records all user actions.

- Lightweight, written purely in Bash — no external dependencies.


Optional or advanced features:

- Colour output for better readability.

- Custom storage directory via configuration file.


## Configuration 

The Recycle Bin system uses a configuration file located at $HOME/BernardoTiago_RecycleBin config that is automatically created during initialization with default values. 

Maximium size of a file: 1024 MB
Retention days: 30
 
## Examples 
[Detailed usage examples with screenshots] 

![Example1](/BernardoTiago_RecycleBin/screenshots/Example1.png)

## Known Issues 
 
## References 

https://www.w3schools.com/
https://stackoverflow.com/questions
https://linuxize.com/


TECHNICAL_DOC.md

Must include: 
• System architecture diagram (ASCII art or image) 
• Data flow diagrams 
• Metadata schema explanation 
• Function descriptions 
• Design decisions and rationale 
• Algorithm explanations 
• Flowcharts for complex operations
