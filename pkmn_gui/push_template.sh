flutter build web --release

# push deployed folder
rsync -avz --delete -e 'ssh -p 26' ./build/web/ url.com:/remote/deploy/location/
# also fix by pushing fix/flutter.js.map to the same folder
rsync -avz --delete -e 'ssh -p 26' ./fix/flutter.js.map url.com:/remote/deploy/location/
