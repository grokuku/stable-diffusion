#!/bin/bash

#Function to move folder and replace with symlink
sl_folder()     {
  echo "moving folder ${1}/${2} to ${3}/${4}"
  mkdir -p "${3}/${4}"
  if [ -d "${1}/${2}" ]; then
    rsync -r "${1}/${2}/" "${3}/${4}/" --verbose
  fi
  echo "removing folder ${1}/${2} and create symlink"
  if [ -d "${1}/${2}" ]; then
    rm -rf "${1}/${2}"
  fi
  
  # always remove previous symlink
  # b/c if user changed target locations current symlink will be incorrect
  if [ -L "${1}/${2}" ]; then
    rm "${1}/${2}"
  fi
  # create symlink
  ln -s "${3}/${4}/" "${1}"
  if [ ! -L "${1}/${2}" ]; then
    mv "${1}/${4}" "${1}/${2}"
  fi
}

clean_env()     {
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${1}
    echo "Done!"
    echo -e "-------------------------------------\n"
fi
}

# Fonction pour mettre à jour un dépôt Git vers une référence spécifique
# ou vers la branche par défaut du remote, en écrasant les modifications locales
# sur les fichiers suivis, mais en conservant les fichiers ajoutés non suivis.
# Arg1: Nom de la variable d'environnement qui contient la référence Git cible (ex: "MY_APP_GIT_REF")
#       Si la variable est vide ou non définie, utilise la branche par défaut du remote.
sync_repo() {
    local git_ref_var_name="$1"
    local target_ref_value=""
    # Vérifie si la variable d'environnement passée en argument est définie ET non vide
    if [ -n "$git_ref_var_name" ] && [ -n "${!git_ref_var_name}" ]; then
        target_ref_value="${!git_ref_var_name}" # Indirection pour obtenir la valeur de la variable
    fi

    echo "Synchronizing repository in $(pwd)..."

    local remote_name=$(git remote | head -n 1)
    if [ -z "$remote_name" ]; then
        echo "Error: No remote configured for this repository. Skipping sync."
        return 1
    fi
    echo "Using remote: $remote_name"

    echo "Fetching latest changes, tags, and pruning from $remote_name..."
    git fetch "$remote_name" --prune --tags --force # --force peut aider avec certains refs conflictuels

    local final_target_ref=""

    if [ -n "$target_ref_value" ]; then
        echo "Target reference specified via $git_ref_var_name: $target_ref_value"
        # Tenter de résoudre la référence. D'abord tel quel (tag, commit, branche locale), puis comme branche distante.
        if git rev-parse --verify "$target_ref_value^{commit}" > /dev/null 2>&1; then # ^{commit} pour s'assurer que c'est un commit-ish (tags annotés)
            final_target_ref="$target_ref_value"
        elif git rev-parse --verify "$remote_name/$target_ref_value^{commit}" > /dev/null 2>&1; then
            final_target_ref="$remote_name/$target_ref_value"
        else
            echo "Warning: Specified target reference '$target_ref_value' not found locally or on remote '$remote_name'."
            echo "Falling back to default remote branch."
            # Laisse final_target_ref vide pour que la logique de fallback s'applique
        fi
    fi

    if [ -z "$final_target_ref" ]; then # Soit non spécifié, soit spécifié mais non trouvé
        local remote_head_branch_name=$(git remote show "$remote_name" | sed -n '/HEAD branch/s/.*: //p')
        if [ -z "$remote_head_branch_name" ]; then
            echo "Warning: Could not automatically determine remote HEAD branch. Attempting common names (main, master)."
            if git show-ref --verify --quiet "refs/remotes/$remote_name/main"; then
                remote_head_branch_name="main"
            elif git show-ref --verify --quiet "refs/remotes/$remote_name/master"; then
                remote_head_branch_name="master"
            else
                echo "Error: Could not determine a default branch (main/master) on remote '$remote_name'."
                # Tentative de garder la branche actuelle si elle a un remote tracking valide
                local current_branch_tracking=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
                if [ -n "$current_branch_tracking" ] && git rev-parse --verify "$current_branch_tracking^{commit}" > /dev/null 2>&1; then
                    echo "Using current branch's remote tracking: $current_branch_tracking"
                    final_target_ref="$current_branch_tracking"
                else
                    echo "Error: Cannot determine a default remote branch to reset to. Aborting sync for this repo."
                    return 1
                fi
            fi
        fi
        if [ -n "$remote_head_branch_name" ] && [ -z "$final_target_ref" ]; then # Si on a trouvé un nom de branche HEAD et que final_target_ref est toujours vide
             final_target_ref="$remote_name/$remote_head_branch_name"
        fi
        echo "Using default remote HEAD: $final_target_ref"
    fi

    if [ -z "$final_target_ref" ]; then
        echo "Error: Could not determine a final target reference. Aborting sync."
        return 1
    fi

    echo "Resetting local repository to match $final_target_ref..."
    local old_sha=$(git rev-parse HEAD 2>/dev/null || echo "no-sha")
    
    # Pour éviter les problèmes avec les branches locales et le passage en detached HEAD:
    # Si la cible finale est une branche distante (comme "origin/main"),
    # on s'assure que la branche locale correspondante est mise à jour (checkout et reset).
    # Si la cible est un tag ou un commit, on passera en detached HEAD, ce qui est normal.
    
    local current_local_branch_name=$(git rev-parse --abbrev-ref HEAD)
    # Vérifier si HEAD est détachée
    local is_detached_head="false"
    if git symbolic-ref -q HEAD >/dev/null; then # Si HEAD est une référence symbolique (une branche)
        is_detached_head="false"
    else # HEAD n'est pas une référence symbolique, donc détachée
        is_detached_head="true"
    fi


    # Est-ce que la cible est une branche distante (ex: origin/main) ?
    if [[ "$final_target_ref" == "$remote_name/"* ]]; then
        local local_branch_candidate=$(echo "$final_target_ref" | sed "s|^$remote_name/||")
        # Si on n'est pas déjà sur cette branche locale ou si on est en detached head
        if [ "$current_local_branch_name" != "$local_branch_candidate" ] || [ "$is_detached_head" == "true" ]; then
            echo "Checking out local branch '$local_branch_candidate' to track '$final_target_ref'."
            # Crée ou change de branche, et la fait pointer sur la cible distante.
            git checkout -B "$local_branch_candidate" "$final_target_ref"
        fi
        # Après le checkout -B, HEAD est sur la branche locale, pointant vers final_target_ref.
        # Un reset --hard pour s'assurer que c'est exactement final_target_ref
        git reset --hard "$final_target_ref"
    else
        # La cible est un tag, un commit, ou une branche locale déjà existante (ou inexistante, auquel cas on aura une erreur).
        # git reset --hard passera en detached HEAD si ce n'est pas une branche locale.
        # Il faut d'abord s'assurer que l'on peut faire un checkout de cette référence pour ne pas casser la branche actuelle si elle n'est pas la cible
        # Sauf si la cible est la branche actuelle
        if [ "$final_target_ref" != "$current_local_branch_name" ] || [ "$is_detached_head" == "true" ]; then
             git checkout "$final_target_ref" # Ceci va passer en detached HEAD si final_target_ref est un tag/commit
        fi
        git reset --hard "$final_target_ref" # Appliquer le reset sur la (potentiellement nouvelle) HEAD
    fi
    
    local new_sha=$(git rev-parse HEAD 2>/dev/null || echo "no-sha")

    if [ "$old_sha" != "$new_sha" ]; then
        echo "Repository updated. HEAD is now at $new_sha."
#        export active_clean=1 # Signaler que le venv pourrait aussi avoir besoin d'être nettoyé
    else
        echo "Repository HEAD ($new_sha) is unchanged or reset to the same state. Local modifications to tracked files (if any) have been reset."
        # Si des modifs locales ont été écrasées, le statut de git diff --staged sera vide.
        # On peut considérer active_clean=1 ici aussi si on veut être sûr
#        if ! git diff-index --quiet HEAD --; then # S'il reste des modifs (non suivies par ex)
#             : # Ne rien faire de spécial, juste pour illustrer
#        else # Si le repo est propre après reset, c'est que les modifs sur fichiers suivis ont été annulées
#             export active_clean=1
#       fi
    fi

    echo "Synchronization complete. Tracked files match $final_target_ref."
    echo "Untracked files (newly added local files) have been preserved."
}

# L'ancienne fonction check_remote est maintenant remplacée en esprit par sync_repo.
check_remote() {
    # Le premier argument de check_remote doit être le nom de la variable d'env pour la ref Git
    # ex: check_remote "FORGE_GIT_REF"
    # Si aucun argument n'est fourni, on passe une chaîne vide à sync_repo,
    # ce qui signifie que sync_repo utilisera la branche par défaut du remote.
    sync_repo "$1"
}


# Fonction récursive pour installer les requirements.txt
#install_requirements() {
#    local directory="$1"
#    local requirements_file="$directory/requirements.txt"

#    if [ -f "$requirements_file" ]; then
#        echo "Installation des dépendances dans $directory ..."
#        pip install -r "$requirements_file"
#        echo "Dépendances installées avec succès dans $directory."
#    fi

#    # Parcours récursif des sous-dossiers
#    for subdir in "$directory"/*; do
#        if [ -d "$subdir" ]; then
#            install_requirements "$subdir"
#        fi
#    done
#}
install_requirements() {
    local directory="$1"
    local requirements_file="$directory/requirements.txt"

    if [ -f "$requirements_file" ]; then
        echo "Installation des dépendances dans $directory ..."
        pip install -r "$requirements_file"
        echo "Dépendances installées avec succès dans $directory."
    fi

    # Parcours des sous-dossiers du premier niveau uniquement
    for subdir in "$directory"/*; do
        if [ -d "$subdir" ]; then
            local subdir_requirements_file="$subdir/requirements.txt"
            if [ -f "$subdir_requirements_file" ]; then
                echo "Installation des dépendances dans $subdir ..."
                pip install -r "$subdir_requirements_file"
                echo "Dépendances installées avec succès dans $subdir."
            fi
        fi
    done
}