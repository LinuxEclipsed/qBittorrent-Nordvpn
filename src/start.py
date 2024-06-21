import base64
import getpass
import hashlib
import os

DEFAULT_PASSWORD = "adminadmin"
CONFIG_LOCATION = "/config/qBittorrent/qBittorrent.conf"
NORD_TOKEN = os.environ.get('NORD_TOKEN', None)
NORD_DNS = os.environ.get('NORD_DNS', '1.1.1.1 1.0.0.1')
ITERATIONS = 100_000
SALT_SIZE = 16

# Get password or set default
password = os.environ.get('QT_PASS', DEFAULT_PASSWORD)

# Generate a cryptographically secure pseudorandom salt
salt = os.urandom(SALT_SIZE)

# PBKDF2 w/ SHA512 hmac
h = hashlib.pbkdf2_hmac("sha512", password.encode(), salt, ITERATIONS)

# Base64 encode and join salt and hash
genPass = base64.b64encode(salt).decode() + ":" + base64.b64encode(h).decode()
genString = f'WebUI\\Password_PBKDF2=\"@{genPass}\"'

configFile = open(CONFIG_LOCATION, 'r')
configFileRead = configFile.read()

# Find hash in config, else create
if "Password_PBKDF2" in configFileRead:
    print("Found password hash in config, skipping!")
    configFile.close()
else:
    configFile.close()
    print("Password hash not found in config, adding!")
    configFile = open(CONFIG_LOCATION, 'a')
    configFile.write(f"\n{genString}")
    configFile.close()

# Start services
os.system("sleep 2 && /etc/init.d/nordvpn start && sleep 2")
os.system(f"nordvpn login --token {NORD_TOKEN} && sleep 2")
os.system(f"nordvpn set dns {NORD_DNS}")
os.system("nordvpn whitelist add port 8080")
os.system("nordvpn connect")
os.system("/usr/local/bin/qbittorrent-nox")