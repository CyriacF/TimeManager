#!/bin/bash

echo "Arrêt de tous les conteneurs Docker en cours..."
docker stop $(docker ps -aq)

echo "Suppression de tous les conteneurs..."
docker rm $(docker ps -aq)

echo "Suppression de tous les volumes..."
docker volume rm $(docker volume ls -q)

echo "Suppression de toutes les images..."
docker rmi -f $(docker images -q)

echo "Nettoyage des builds Docker..."
docker builder prune -af

echo "Tous les conteneurs, volumes, images et builds ont été supprimés."
