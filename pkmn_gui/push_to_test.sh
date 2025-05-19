flutter build web --release --dart-define=API_URL="https://pkmnapi.notawebsitejustmynotebookgoaway.com"

# push deployed folder
rsync -avz --delete -e 'ssh -p 26' /Users/arnesahlberg/Kod/Projects/PkmnJakt/pkmn_gui/build/web/ notawebsitejustmynotebookgoaway.com:/home/arnesahlberg/otherhome/apps/pkmn_jakt_website/
# also fix by pushing fix/flutter.js.map to the same folder
rsync -avz --delete -e 'ssh -p 26' /Users/arnesahlberg/Kod/Projects/PkmnJakt/pkmn_gui/fix/flutter.js.map notawebsitejustmynotebookgoaway.com:/home/arnesahlberg/otherhome/apps/pkmn_jakt_website/
