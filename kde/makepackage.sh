#!/bin/bash
rm ../panon/__pycache__ -r
rm ./panon.plasmoid
rm ./plasmoid/contents/shaders/example-*
zip -r panon.plasmoid ./plasmoid 
