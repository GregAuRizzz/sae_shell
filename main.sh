#!/bin/bash

source functions.sh

lire_donnees "$1"
initialiser_grille

echo "================================"

echo "Grille de base, pas encore remplie :"
afficher_tableau
echo "================================"
remplir_cases_evidentes
echo "Cases évidentes complétées :"
afficher_tableau
echo "================================"

eliminer_possibilites
eliminer_possibilites

echo "Grille complète"
afficher_tableau
echo "================================"

ecrire_reponse_dans_fichier_recursive "output.txt"
