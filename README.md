# Follow Me — suivi de visage pour caméra PTZ

**Follow Me** est un script Python qui repère un visage dans le flux vidéo d’une caméra et pilote ses axes **pan/tilt** pour le garder dans le champ. Il utilise OpenCV et le modèle de détection YuNet, et commande les moteurs par les contrôles **V4L2** du noyau Linux. La version la plus complète fournie ajoute un zoom automatique, une icône de zone de notification avec réglages, ainsi qu’une installation optionnelle comme service utilisateur systemd sous NixOS.

> **État du projet :** prototype dépendant du matériel, des contrôles V4L2 exposés par la caméra, du pilote et de la session graphique. Les fichiers fournis ne contiennent ni tests automatisés ni matrice de compatibilité matérielle. Vérifiez les contrôles et essayez d’abord le lancement interactif avant d’installer le service.

## Fonctionnalités

- Détection de visages YuNet par `cv2.FaceDetectorYN` et suivi du centre de la cible.
- Commandes PTZ V4L2 : correction pan/tilt, zones mortes, lissage, inversion d’axes, limite de déplacement et recentrage après perte de cible.
- Réinitialisation matérielle pan/tilt au démarrage, désactivable séparément du recentrage logiciel.
- Zoom automatique : commande un contrôle de zoom V4L2 exploitable lorsqu’il existe, sinon utilise un recadrage numérique. Il est activé par défaut dans les dernières versions.
- Aperçu vidéo et, par défaut dans les versions avec interface, icône de zone de notification, démarrage/arrêt du suivi et panneau de réglages.
- Chargement automatique des dépendances au moyen d’un shell Nix temporaire sur NixOS lorsque des prérequis manquent.
- Dans la version v0.7, installation et désinstallation d’un service utilisateur systemd lié à la session graphique.

## Matériel et environnement

- Linux avec une caméra PTZ exposant les commandes pan/tilt sous **V4L2**. Les contrôles disponibles diffèrent selon les appareils et leurs pilotes ; l’existence d’un contrôle de zoom matériel n’est pas garantie.
- Python **3.9 ou supérieur** conseillé (le code utilise `argparse.BooleanOptionalAction`).
- Pour la détection : OpenCV avec `cv2.FaceDetectorYN` (le diagnostic du script indique OpenCV 4.5.4 minimum), NumPy et le modèle YuNet ONNX.
- `v4l-utils` / `v4l2-ctl` est nécessaire aux commandes de contrôle et au reset matériel.
- Pour l’interface : Tkinter, Pillow, pystray et les dépendances graphiques/DBus. Sous NixOS, le shell intégré prépare notamment OpenCV compilé avec GTK, Tk, PyGObject et AppIndicator. L’icône est destinée à une session KDE/Plasma avec DBus et StatusNotifier disponibles ; le code vérifie ces conditions.
- L’utilisateur doit avoir accès en lecture/écriture au nœud vidéo (souvent via le groupe `video`).

Le script ne fournit pas le fichier de modèle. Téléchargez YuNet depuis le dépôt OpenCV/Hugging Face, puis placez-le à côté du script :

```sh
curl -L -o face_detection_yunet_2023mar.onnx \
  https://huggingface.co/opencv/face_detection_yunet/resolve/main/face_detection_yunet_2023mar.onnx
```

Le modèle et ses conditions de redistribution sont distincts du code de ce dépôt : consultez sa source avant de le redistribuer ou de l’inclure dans une publication.

## Installation et premier lancement

Les exemples ci-dessous utilisent le fichier **v0.7** fourni, `follow_me_7.py`. Si le dépôt publie la version sélectionnée sous le nom `follow_me.py`, remplacez ce nom dans les commandes. La dernière version peut relancer automatiquement un shell Nix sur NixOS en cas de dépendances absentes ; hors NixOS, installez vous-même les dépendances système et Python ci-dessus.

Vérifiez d’abord les périphériques identifiés :

```sh
ls -l /dev/v4l/by-id/
v4l2-ctl --device /dev/v4l/by-id/VOTRE-PERIPHERIQUE-video-index0 --list-ctrls
```

Démarrez avec un chemin stable `/dev/v4l/by-id/...` si plusieurs nœuds vidéo existent :

```sh
python3 follow_me_7.py \
  --device /dev/v4l/by-id/VOTRE-PERIPHERIQUE-video-index0 \
  --no-reset --max-delta 200 --preview
```

Le script réinitialise les moteurs au démarrage, sauf si `--no-start-reset` est passé. Il ignore ensuite 12 images pour stabiliser l’exposition. `--no-reset` désactive le recentrage logiciel après acquisition ; il **ne** désactive **pas** à lui seul le reset matériel initial. Pour éviter ce dernier, ajoutez `--no-start-reset`.

Arrêt : `Ctrl+C`, ou la touche `q` lorsque l’aperçu est ouvert. Pour la liste des options et leurs valeurs par défaut :

```sh
python3 follow_me_7.py --help
```

### Réglages courants

| Option | Effet |
|---|---|
| `--device CHEMIN` | Sélectionne explicitement le nœud V4L2. |
| `--preview` | Ouvre l’aperçu vidéo ; nécessite un backend graphique. |
| `--no-tray` | Mode terminal, sans icône ni panneau de réglages. |
| `--no-reset` | Désactive le recentrage logiciel après la première image. |
| `--no-start-reset` | N’envoie pas le reset matériel pan/tilt au démarrage. |
| `--no-auto-zoom` | Désactive le zoom automatique (activé par défaut dans v0.3 et suivantes). |
| `--zoom-target-ratio 0.25` | Définit le rapport cible largeur du visage / largeur de l’image ; doit être entre 0 et 1. |
| `--zoom-max 3.0` | Limite le facteur maximal du zoom numérique. |
| `--zoom-step N` | Limite le pas du zoom matériel par commande. |
| `--invert-pan` / `--no-invert-tilt` | Ajuste le sens des axes ; le tilt est inversé par défaut. |
| `--width`, `--height`, `--fps` | Paramètres de capture ; les dimensions ne dépassent pas 640 × 480 dans le code fourni. |
| `--score`, `--smooth`, `--deadzone X Y` | Seuil de détection, lissage du suivi et zone morte. |
| `--lost-recenter SECONDES` | Délai avant recentrage après perte de cible ; `0` désactive ce recentrage. |

Consultez `--help` : l’ensemble des options varie entre les versions historiques et toutes les options ne sont pas nécessaires à chaque caméra.

## Service utilisateur systemd sous NixOS (v0.7)

L’installation est prévue pour NixOS avec `nix-shell` et une session graphique utilisateur. Les options supplémentaires fournies à l’installation sont inscrites dans la commande du service ; utilisez donc ici un mode sans zone de notification si vous le souhaitez :

```sh
python3 follow_me_7.py --install-service --no-tray --no-reset --max-delta 200
systemctl --user status follow-me
journalctl --user -u follow-me -f
```

La commande installe une copie du script et le shell Nix sous `~/.local/share/follow_me/`, puis écrit et active `~/.config/systemd/user/follow-me.service`. L’unité est rattachée à `graphical-session.target`, redémarre en cas d’échec et est activée pour les sessions graphiques. Si le modèle est présent à côté du script, il est également copié ; sinon, l’installation affiche un avertissement et le suivi ne pourra pas démarrer avant son ajout dans le répertoire de service.

Pour désinstaller l’unité :

```sh
python3 follow_me_7.py --uninstall-service
```

La désinstallation arrête/désactive le service et supprime l’unité systemd, mais conserve les fichiers sous `~/.local/share/follow_me/` et les réglages. Pour gérer les réglages, lancez le script en mode interactif ou modifiez `~/.config/follow_me/settings.json`.

## Versions historiques fournies

La série décrit l’évolution du script, pas sept implémentations toutes distinctes : les fichiers `follow_me_1.py` et `follow_me_2.py` fournis sont identiques octet pour octet ; le fichier `Logitech-QuickCam-Sphere-NixOs.py` est identique à `follow_me_7.py`.

| Version | Évolution visible  |
|---|---|
| **v0.1** | Basic functions |
| **v0.2** | Suivi facial PTZ V4L2, aperçu en option, contrôles de caméra et bootstrap des dépendances sur NixOS. |
| **v0.3** | Ajout du zoom automatique : détection des contrôles de zoom V4L2 et zoom numérique de repli, avec paramètres de cible et de limite. |
| **v0.4** | Ajout de l’interface de zone de notification, des réglages enregistrés et actualisables, et du shell Nix enrichi en dépendances graphiques. |
| **v0.5** | Refonte de l’aperçu pour l’intégrer aux boucles Tkinter, ajout d’un mode aperçu console et de la fermeture des instances précédentes. |
| **v0.6** | Ajustements du shell Nix et du contrôle des dépendances, prise en compte des réglages d’inversion à chaud et robustesse accrue de l’arrêt de l’interface. |
| **v0.7** | Ajout de l’installation/désinstallation du service utilisateur systemd sous NixOS, démarré avec la session graphique. 
| **v0.8** | Ajout de la copie de signal video. 

Le fichier `Logitech-QuickCam-Sphere-NixOs.py` en est une copie identique de la derniere version |

## Diagnostic et limites

- Vérifiez les capacités exposées par la caméra avec `v4l2-ctl --device CHEMIN --list-ctrls`. Le code ouvre le même nœud une fois pour les contrôles PTZ et une fois pour la capture ; le comportement peut dépendre du pilote.
- Si aucun contrôle de zoom V4L2 utilisable n’est disponible, la version avec zoom peut recourir au recadrage numérique ; cela ne crée pas un zoom optique.
- Pour un problème de droits, vérifiez les permissions du nœud vidéo et l’appartenance au groupe `video`, puis reconnectez la session si nécessaire.
- Le mode tray dépend d’une session graphique et de DBus/StatusNotifier. Utilisez `--no-tray` pour ne pas lancer l’icône ; `--preview` demande en plus un environnement graphique.
- Une réinitialisation pan/tilt entraîne un mouvement physique de la caméra. Dégagez son débattement et vérifiez la direction des axes avant de laisser le suivi fonctionner sans surveillance.
- Aucune exécution sur caméra réelle n’a été réalisée lors de la rédaction de ce README ; la compatibilité de votre modèle et les performances restent à valider localement.

## Licence

Le projet est destiné à être publié sous la **GNU General Public License, version 3** (**GNU GPL v3**). Ajoutez au dépôt le fichier `LICENSE` contenant le texte intégral officiel de la GPL-3.0 ; le README seul ne constitue pas le texte de licence. Cette mention concerne le code du projet et ne détermine pas la licence du modèle ONNX ni celles des dépendances tierces.


## Nouveautés et notes de version (juillet 2026)

- **NixOS, noyau 7.0.x et v4l2loopback 0.15.3 :** le périphérique vidéo virtuel peut échouer à l’appel `VIDIOC_STREAMON` avec `EIO` sur les noyaux ≥ 7.0. Préférez alors le périphérique physique, identifié sous `/dev/v4l/by-id/...`.

  Exemple pour la caméra Logitech QuickCam Orbit sur NixOS :

  ```sh
  python3 follow_me_7.py --device /dev/v4l/by-id/usb-046d_081d_XXXX-video-index0 --no-reset --max-delta 200 --preview
  ```

- **Résolution des collisions de périphériques :** utilisez les chemins stables `/dev/v4l/by-id/` plutôt que `/dev/videoN`, qui peuvent désigner des périphériques différents selon l’ordre de détection.
- **Fichier de configuration :** `~/.config/follow_me/settings.json` est créé au premier lancement, persiste entre les sessions et survit aux `nixos-rebuild` (les chemins du store Nix sont immuables).
- **`exclusive_caps=1` avec v4l2loopback :** un seul processus à la fois peut ouvrir le périphérique virtuel. Cette option évite les conflits d’accès avec VLC ou d’autres lecteurs.
