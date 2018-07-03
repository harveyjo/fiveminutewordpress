# fiveminutewordpress
Spin-Up a Containerized Wordpress Blog or website in five minutes with MySQL + phpMyAdmin. Uses the latest version of wordpress and initializes a composer project with a docker-compose.yaml.

# Requirements
	- Docker & Docker-Compose
	- CURL
	- PHP installed globally

# Installation

- Clone the Repo  `git@github.com:harveyjo/fiveminutewordpress.git`
- Make sure Docker is running `docker -v`
- Run the install script ` sudo ./install.sh -n YourWebsiteName -d YourDatabaseName -p CHANGE_mysql_password`