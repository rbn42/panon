
rm ../panon/__pycache__ -r

kpackagetool5 -t Plasma/Applet --install plasmoid
kpackagetool5 -t Plasma/Applet --upgrade plasmoid

rm ./panon.plasmoid
zip -r panon.plasmoid ./plasmoid 
