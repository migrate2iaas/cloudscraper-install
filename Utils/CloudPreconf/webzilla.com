region=https://auth.nl01.cloud.webzilla.com:5000/v2.0
endpoint=https://auth.nl01.cloud.webzilla.com:5000/v2.0
swift_endpoint = https://eu01-auth.webzilla.com:5000/v2.0
swift_tennant = 2344
swift_user = 3186
swift_password = icafLFsmAOswwISn
swift_container = cloudscraper-pub
swift_compression = 1
network=network-for-az1
ip_pool=internet-for-az1
resume_file_path=C:\cloudscraper-agent\parts
use_new_channel = 1