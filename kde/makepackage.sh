#!/bin/bash
rm ../panon/__pycache__ -r
rm plasmoid/contents/scripts/__pycache__/ -r
rm ./panon.plasmoid
zip -r panon.plasmoid ./plasmoid 
