python build.py

rm ../panon/__pycache__ -r

kpackagetool5 -t Plasma/Applet --install plasmoid
kpackagetool5 -t Plasma/Applet --upgrade plasmoid

zip -r panon.plasmoid ./plasmoid 
