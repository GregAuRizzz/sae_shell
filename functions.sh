#!/bin/bash

declare -A grid # grille
size=3

lire_donnees() {
    local file="$1"  

    if [ ! -f "$file" ]; then
        echo "Le fichier $file n'existe pas."
        return 1
    fi

    top_indices=$(sed -n '2p' "$file")  
    IFS=',' read -r -a top_indices_array <<< "$top_indices"

    bottom_indices=$(sed -n '6p' "$file")
    IFS=',' read -r -a bottom_indices_array <<< "$bottom_indices"

    row_indices=()
    for i in {3..5}; do
        line=$(sed -n "${i}p" "$file")
        IFS=',' read -r left right <<< "$line"
        row_indices+=("$left,$right")
    done
}


initialiser_grille() {
    for ((i=0; i<size; i++)); do
        for ((j=0; j<size; j++)); do
            grid[$i,$j]="1,2,3"
        done
    done

    for ((i=0; i<size; i++)); do
        grid[$i,-1]="${row_indices[i]%%,*}" 
        grid[$i,$size]="${row_indices[i]#*,}"
    done

    for ((j=0; j<size; j++)); do
        grid[-1,$j]="${top_indices_array[j]}"
        grid[$size,$j]="${bottom_indices_array[j]}"
    done
}



afficher_tableau() {
    printf "    "
    for ((j=0; j<size; j++)); do
        printf "%-7s " "${grid[-1,$j]}"
    done
    echo

    for ((i=0; i<size; i++)); do
        printf "%-3s " "${grid[$i,-1]}"  # gauche
        for ((j=0; j<size; j++)); do
            printf "%-7s " "${grid[$i,$j]}"  # valeur dans la grille
        done
        printf "%-3s\n" "${grid[$i,$size]}"  # droite
    done

    # bas
    printf "    "
    for ((j=0; j<size; j++)); do
        printf "%-7s " "${grid[$size,$j]}"
    done
    echo
}

remplir_cases_evidentes() {
    for ((i=0; i<size; i++)); do
        if [[ "${grid[$i,-1]}" -eq "$size" ]]; then  # si c'est = a la taille
            for ((j=0; j<size; j++)); do
                grid[$i,$j]=$((j+1))  # remplir 1 2 3 4
            done
        elif [[ "${grid[$i,-1]}" -eq 1 ]]; then  # si c'est 1
            grid[$i,0]=$size # c'est le premier bat 
        fi

        if [[ "${grid[$i,$size]}" -eq "$size" ]]; then  
            for ((j=0; j<size; j++)); do
                grid[$i,$((size-j-1))]=$((j+1))  #la ligne a l'envers
            done
        elif [[ "${grid[$i,$size]}" -eq 1 ]]; then  # Si la contrainte de droite est 1
            grid[$i,$((size-1))]=$size  # grand bat a droite
        fi
    done

    for ((j=0; j<size; j++)); do
        if [[ "${grid[-1,$j]}" -eq "$size" ]]; then  
            for ((i=0; i<size; i++)); do
                grid[$i,$j]=$((i+1)) 
            done
        elif [[ "${grid[-1,$j]}" -eq 1 ]]; then
            grid[0,$j]=$size
        fi

        if [[ "${grid[$size,$j]}" -eq "$size" ]]; then
            for ((i=0; i<size; i++)); do
                grid[$((size-i-1)),$j]=$((i+1))
            done
        elif [[ "${grid[$size,$j]}" -eq 1 ]]; then 
            grid[$((size-1)),$j]=$size
        fi
    done
}

eliminer_possibilites() {
    for ((i=0; i<size; i++)); do
        for ((j=0; j<size; j++)); do
            if [[ "${grid[$i,$j]}" =~ ^[0-9]+$ ]]; then  # si c bien une valeur 
                continue  
            fi

            valeur_utilisees=""  # valeurs utilisées
            for ((k=0; k<size; k++)); do
                if [[ "${grid[$i,$k]}" =~ ^[0-9]+$ ]]; then
                    valeur_utilisees+="${grid[$i,$k]},"  # ajout valeur ligne
                fi
                if [[ "${grid[$k,$j]}" =~ ^[0-9]+$ ]]; then
                    valeur_utilisees+="${grid[$k,$j]},"  # ajout valeur colonne
                fi
            done

            IFS=',' read -r -a possibles <<< "${grid[$i,$j]}"

            new_possibles=()  # Tableau pour stocker les nouvelles possibilités
            for value in "${possibles[@]}"; do
                if [[ ! "$valeur_utilisees" =~ "$value" ]]; then  
                    new_possibles+=("$value")  # Ajoute valeur au new tableau
                fi
            done

            if [ ${#new_possibles[@]} -eq 0 ]; then
                grid[$i,$j]=""  # Vide la case si aucune possibilité
            else
                grid[$i,$j]=$(IFS=','; echo "${new_possibles[*]}")  # maj nouvelles possibilités
            fi
        done
    done 
}

ecrire_reponse_dans_fichier_recursive() {
    local file="$1"
    local i="${2:-0}" # ligne a print
    local j="${3:-0}" # colonne a print

    if (( i >= size )); then
        return
    fi

    if (( i == 0 && j == 0 )); then
        > "$file" # tips effacer un fichier
    fi

    # ecriture si c bien un nombre :
    if [[ -n "${grid[$i,$j]}" && "${grid[$i,$j]}" =~ ^[0-9]+$ ]]; then
        echo -n "${grid[$i,$j]} " >> "$file"
    fi

    # passage colonne/ligne suivante
    if (( j + 1 < size )); then
        ecrire_reponse_dans_fichier_recursive "$file" "$i" "$((j + 1))"
    else
        # fin ligne
        echo >> "$file"
        ecrire_reponse_dans_fichier_recursive "$file" "$((i + 1))" 0
    fi
}

