# Linux Recycle Bin System 
 
## Author 
[Your Name] 
[Your Student ID] 

Bernardo Mota Coelho 
125059

Tiago Francisco Crespo do Vale
125913
 
## Description 
Our project consists in a Linux Recycle Bin Simulation. It aims to replicate the tradition Recycle Bin, but in a command-line environment using the terminal. 
The system allows the user to delete files, list them and recover to his original location
 
## Installation 
[How to install/setup] 
 
If repository is online and public: 

type on terminal: git clone https://github.com/Bernardo2409/SO_Project 

next type: cd BernardoTiago_RecycleBin

If repository is in .rar or .zip

download the files, unzip and type on terminal: cd BernardoTiago_RecycleBin



## Usage 
[How to use with examples] 

chmod +x recycle_bin.sh

./recycle_bin.sh <comand> <options>

FALTAM OS EXEMPLOS
 
 
## Features 
- [List of implemented features] 
- [Mark optional features] 


- Safe deletion of files — prevents permanent data loss.

- Restore deleted files by name or ID.

- Metadata tracking (file name, original path, deletion date, size, owner, permissions).

- Simple and detailed list views (list and list --detailed).

- Search function for locating deleted files quickly.

- Option to permanently empty the bin (empty / empty --force).

- Automatic creation of the Recycle Bin directory and configuration file.

- Integrated logging system that records all user actions.

- Lightweight, written purely in Bash — no external dependencies.



Optional or advanced features:


- Colour output for better readability.

- Custom storage directory via configuration file.

- Test suite with automated validation functions (assert_success, assert_fail).
 
## Configuration 
[How to configure settings] 

The Recycle Bin system uses a configuration file located at $HOME/BernardoTiago_RecycleBin config that is automatically created during initialization with default values.
 
## Examples 
[Detailed usage examples with screenshots] 
 
## Known Issues 
[Any limitations or bugs] 
 
## References 
[Resources used] 
TECHNICAL_DOC.md



Must include: 
• System architecture diagram (ASCII art or image) 
• Data flow diagrams 
• Metadata schema explanation 
• Function descriptions 
• Design decisions and rationale 
• Algorithm explanations 
• Flowcharts for complex operations