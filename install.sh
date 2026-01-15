## Standard installation (/usr/local guest=/overlay)
# ./configure
# cd build
# sudo ./install.sh

# System-wide installation (/usr)
./configure --prefix=/usr --guest=/overlay
cd build
sudo make install

## Custom location
# ./configure --prefix=/opt/overlight --guest=/mnt/overlay
# cd build
# sudo make install
