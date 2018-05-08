#!/usr/bin/env bash
echo "Installing HueTerm..."
sudo -p "Password: " echo

# Install required dependencies
echo "Installing dependencies..."
sudo apt install -y git jq

# Check if an older version of HueTerm is already installed
if [[ -d "/usr/share/hueterm" ]]; then
  echo "Old version of HueTerm detected, removing..."
  sudo rm -R /usr/share/hueterm
fi

# Clone the repository
sudo git clone https://github.com/DeadNetOfficial/hueterm.git /usr/share/hueterm

# Give executable permissions to main executable
sudo chmod +x /usr/share/hueterm/hueterm.sh

# Make symbolic links
if [[ ! -f "/usr/bin/hueterm" ]]; then
  echo "Creating symbolic links..."
  sudo ln -s /usr/share/hueterm/hueterm.sh /usr/bin/hueterm
fi

# Notify the user a successfull installation and exit afterwards
echo "Done!" && exit 0
