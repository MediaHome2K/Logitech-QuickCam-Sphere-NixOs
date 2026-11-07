# Follow Me — Linux PTZ face tracking / suivi de visage PTZ sous Linux

[English](#english) | [Français](#francais)

## English <a id="english"></a>

### Quick Start / Démarrage rapide

1. **Prepare the files.** Put `linux_motorized_camera_driver.py` and `camera_driver.lng` in the same folder. Download `face_detection_yunet_2023mar.onnx` into that folder too (the script requires this model):

   ```sh
   curl -L -o face_detection_yunet_2023mar.onnx \
     https://huggingface.co/opencv/face_detection_yunet/resolve/main/face_detection_yunet_2023mar.onnx
   ```
2. **Dependencies.** On NixOS, start with `python3`; if required dependencies are missing and `nix-shell` is available, the script prepares and enters its temporary Nix shell automatically. On Debian/Ubuntu, install dependencies yourself (see [Dependencies](#dependencies)).
3. **Check the command line, then test.** This quick check does not move the camera:

   ```sh
   python3 linux_motorized_camera_driver.py --help
   ```

   To try tracking on the detected camera without the startup hardware reset or tray icon:

   ```sh
   python3 linux_motorized_camera_driver.py --no-tray --no-start-reset
   ```

   Add `--preview` only in a graphical session. For a specific camera, pass `--device /dev/v4l/by-id/YOUR-DEVICE-video-index0`. The script uses V4L2 camera controls; check permissions and hardware before use. The model, camera and required dependencies must be available for tracking.

### Features

- YuNet face detection with `cv2.FaceDetectorYN` and face tracking.
- PTZ axis control with dead zones, smoothing, speed adjustment, axis inversion and a correction limit.
- Hardware pan/tilt reset at startup and software recentering after target loss are configured separately.
- Automatic zoom when available. The script uses a usable V4L2 zoom control or falls back to digital zoom; digital zoom is cropping, not optical zoom.
- Graphical mode: notification-area icon, tracking start/stop, preview, settings, manual control and pan/tilt reset.
- Terminal mode without an icon, with optional graphical preview.
- VirtualVideo option to copy the stream to a `v4l2loopback` device using `ffmpeg`.
- On NixOS, automatic restart inside an integrated Nix shell when prerequisites are missing and `nix-shell` is available. On Debian and derivatives, missing dependencies are reported but not installed automatically.

### Dependencies

#### Required for tracking

- Linux and Python 3 (Python 3.9 or newer is recommended; the code uses `argparse.BooleanOptionalAction`).
- A camera accessible to the script, with suitable V4L2 PTZ controls. By default the script detects `/dev/v4l/by-id/*-video-index*` nodes; `--device` selects one explicitly.
- OpenCV with `cv2.FaceDetectorYN` (the script's check requires a YuNet-capable version, at least OpenCV 4.5.4) and NumPy.
- The YuNet model `face_detection_yunet_2023mar.onnx`.
- `v4l-utils`, which provides `v4l2-ctl`, required for resets and camera control commands.
- Read/write permission for the video device. Depending on the distribution, access may require membership in the `video` group and a new login session.

By default, the script requests **640 × 480 at 30 frames/s**. The accepted resolution is limited to a maximum of 640 × 480; the camera must support the requested mode.

#### Graphical and virtual-video features

- Tray/settings mode uses Tkinter, Pillow, `pystray` and a desktop environment. The script's tray check verifies DBus, Plasma/KDE and the StatusNotifierWatcher service. Use `--no-tray` to skip this mode.
- `--preview` requires a graphical environment (DISPLAY or WAYLAND_DISPLAY), Tkinter, Pillow and an OpenCV build with a GTK or Qt backend. In console mode without the tray, preview also opens in a Tk window.
- VirtualVideo requires the `v4l2loopback` kernel module loaded with a configured device, plus `ffmpeg`. Compatibility of the module with the selected kernel is not guaranteed by the script.

### YuNet Model

The script does not include the ONNX model. Download it to the same directory as the script (or pass its location with `--model`):

```sh
curl -L -o face_detection_yunet_2023mar.onnx \
  https://huggingface.co/opencv/face_detection_yunet/resolve/main/face_detection_yunet_2023mar.onnx
```

The model and its redistribution terms are separate from the code and its dependencies; consult its source before redistribution.

### Installation and First Run

Place `linux_motorized_camera_driver.py` and the model in an accessible directory. A stable camera path is recommended:

```sh
ls -l /dev/v4l/by-id/
v4l2-ctl --device /dev/v4l/by-id/YOUR-DEVICE-video-index0 --list-ctrls
python3 linux_motorized_camera_driver.py \
  --device /dev/v4l/by-id/YOUR-DEVICE-video-index0 \
  --no-reset --max-delta 200 --preview
```

`--no-reset` disables software recentering after the first image; it **does not** disable the hardware pan/tilt reset at startup. To prevent that movement, add `--no-start-reset`. The two options have different effects.

After acquiring the first image, the program skips 12 frames to let exposure stabilize. Stop with `Ctrl+C` in terminal mode or the `q` key with console preview; in the interface, choose Quit or close the application. To see syntax and default values:

```sh
python3 linux_motorized_camera_driver.py --help
```

#### NixOS

Run the script with `python3`. If checked prerequisites are missing and `nix-shell` is available, the script writes a temporary `shell.nix` and relaunches in that shell with required packages (OpenCV with GTK, NumPy, pystray, Pillow, Tkinter, PyGObject, `v4l-utils` and graphical libraries; `ffmpeg` is added when VirtualVideo is requested). The automatic relaunch is guarded against loops.

The integrated shell evaluates `import <nixpkgs> {}`; nixpkgs selection therefore depends on the active Nix configuration on that machine (channel, flake/profile or available Nix environment). It also includes `ffmpeg`. Do not assume two computers or profiles have the same packages or kernel. Test the script and NixOS attributes on each target configuration; the script does not configure the `v4l2loopback` kernel module.

#### Debian, Ubuntu and derivatives

The script does not install dependencies. Its diagnostic suggests this command, which you should adapt to the features you use:

```sh
sudo apt install python3-opencv python3-numpy v4l-utils ffmpeg python3-pil python3-tk python3-pystray
```

The system OpenCV version must actually provide `FaceDetectorYN`; having `python3-opencv` installed alone does not guarantee this. `ffmpeg` is needed for VirtualVideo sharing, while Pillow/Tkinter/pystray support the interface.

### Settings, Language and Axis Inversion

In tray mode, open **Settings** from the icon menu. Available commands and settings include starting/stopping tracking, automatic zoom, preview, VirtualVideo, manual control and pan/tilt reset. The panel lets you set maximum zoom, target face size, speed, horizontal and vertical dead zones, preview, language and axis inversion.

By default, **pan** is not inverted and **tilt** is inverted. To correct a direction that is opposite to what you expect:

- In the panel, toggle **Invert left/right (pan)** and **Invert up/down (tilt)**.
- Or use `--invert-pan` to invert left/right and `--no-invert-tilt` to disable the default up/down inversion. `--invert-tilt` explicitly enables it.

Interface settings are saved to:

```text
~/.config/follow_me/settings.json
```

The file is created when settings are saved. It belongs to the user account and is not in the Nix store; a NixOS rebuild does not replace it. In `--no-tray` mode, the script does not load this settings panel, so use CLI options instead.

#### Interface language

Interface text is read from `camera_driver.lng`, placed **beside the script**. This is an INI-format file with `[en]` and `[fr]` sections. The code first uses text from the selected language, then the corresponding English text, and finally the key identifier if no translation is available. The language selected in Settings is saved as `language` in `settings.json` and takes effect after restart.

When installing a service, the program copies `camera_driver.lng` beside the script copy if the file is present at installation time. Later changes to the source file do not update the service copy; reinstall the service to refresh its files.

### All Command-Line Options

The options below are declared by `argparse` in the supplied script. Numeric parameters have validity checks; defaults are shown where defined by the code.

| Option | Default / effect |
|---|---|
| `-h`, `--help` | Show help and exit. |
| `-d`, `--device PATH` | V4L2 node to use; automatic selection otherwise. |
| `--model PATH` | ONNX model path; defaults to the expected YuNet file beside the script. |
| `--width N` | Capture width, default `640`, from 1 to 640. |
| `--height N` | Capture height, default `480`, from 1 to 480. |
| `--fps N` | Requested frames per second, default `30`, minimum 1. |
| `--detect-every N` | Detection interval, default `2`, minimum 1. |
| `--score N` | Detection threshold, default `0.5`, greater than 0 and at most 1. |
| `--smooth N` | Tracking smoothing, default `0.6`, greater than 0 and at most 1. |
| `--deadzone X Y` | Horizontal and vertical dead zone, default `16 12`; non-negative numbers. |
| `--kp-pan N` | Pan gain, default `6.0`; non-negative. |
| `--kp-tilt N` | Tilt gain, default `4.5`; non-negative. |
| `--invert-pan` | Invert left/right; disabled by default. |
| `--invert-tilt`, `--no-invert-tilt` | Enable/disable up/down inversion; enabled by default. |
| `--no-start-reset` | Do not send hardware `pan_reset`/`tilt_reset` commands at startup. |
| `--motor-interval N` | Motor interval, default `0.06` seconds; non-negative. |
| `--max-delta N` | Maximum correction per axis per command, default `1000.0`; strictly positive. |
| `--lost-recenter N` | Seconds before recentering after target loss, default `3.0`; `0` disables this recentering. |
| `--frame-timeout N` | Wait for a new frame, default `5.0` seconds; strictly positive. |
| `--no-auto-zoom` | Disable automatic zoom, enabled by default. |
| `--zoom-target-ratio N` | Target face width / image width, default `0.25`, strictly between 0 and 1. |
| `--zoom-max N` | Maximum digital zoom factor, default `3.0`, minimum 1. |
| `--zoom-step N` | Maximum step per hardware-zoom command; defaults to 3 camera-control steps. If supplied, must be strictly positive. |
| `--preview` | Enable video preview; requires a graphical environment. |
| `--virtual-video` | Request stream copy to a `v4l2loopback` device. |
| `--virtual-device PATH` | Loopback node to use; automatic detection otherwise. A supplied path must be recognized as `v4l2loopback`. |
| `--no-tray` | Terminal mode without icon or settings panel. |
| `--no-reset` | Disable software recentering after the first image; startup hardware reset remains independent. |
| `--install-service` | Install, enable and start a user systemd service, preserving other CLI arguments in its command. |
| `--uninstall-service` | Stop/disable and remove the user systemd unit; keep application files and settings. |

Useful terminal commands:

```sh
# No icon or preview; disable the startup hardware reset
python3 linux_motorized_camera_driver.py --no-tray --no-start-reset

# Console preview (graphical window) without a notification icon
python3 linux_motorized_camera_driver.py --no-tray --preview

# Invert pan and disable the default tilt inversion
python3 linux_motorized_camera_driver.py --invert-pan --no-invert-tilt
```

### Share the Stream with VirtualVideo

Sharing is disabled by default. Enable it with `--virtual-video` or in the tray menu. The script keeps the physical camera open for tracking and PTZ control, then writes a copy of the images to the `v4l2loopback` node. Other applications must select **the virtual camera**, not the physical camera. The copy does not release the original camera.

Example NixOS configuration to adapt to the nixpkgs version and selected kernel:

```nix
{ config, ... }:
{
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="CamPartagee" exclusive_caps=1
  '';
}
```

The package attribute may not exist for every kernel/channel. Verify availability and compatibility before adding this snippet. Rebuild/reboot to load the module. For temporary use, the script also gives the `sudo modprobe` command for this example (device 10). The module must be loaded before the graphical session and the Follow Me service. The user also needs permissions for the video node, often through the `video` group.

The loopback node is detected automatically; force a recognized node with `--virtual-device /dev/videoN`. Example:

```sh
python3 linux_motorized_camera_driver.py --virtual-video --virtual-device /dev/video10
v4l2-ctl --list-devices
```

If no loopback is detected, tracking continues but the stream is not shared. If `ffmpeg` is missing or the output cannot be opened, a warning is shown and video output may be disabled. With `exclusive_caps=1`, wait for the “VirtualVideo active” message before selecting the virtual camera in another application; that application may need to refresh its camera list. Details depend on the application, driver and session permissions.

### Install as a User systemd Service

Installation copies the script to `~/.local/share/follow_me/` as `follow_me_7.py`, copies the YuNet model and `camera_driver.lng` if present beside the script, then creates `~/.config/systemd/user/follow-me.service`. It runs `systemctl --user daemon-reload`, enables and starts the unit. The service is attached to `graphical-session.target` and restarts on failure.

On NixOS, the script also installs its integrated `shell.nix` in that directory and the service command uses `nix-shell`. On other systems, the unit uses the Python interpreter current at installation. The graphical session and camera permissions must be available to the user service.

```sh
# Install and start with these options (they are recorded in the service)
python3 linux_motorized_camera_driver.py --install-service --no-tray --no-reset --max-delta 200

# Check status and follow logs
systemctl --user status follow-me
journalctl --user -u follow-me -f

# Uninstall the unit
python3 linux_motorized_camera_driver.py --uninstall-service
```

In this example, `--no-reset` disables software recentering, not the initial hardware reset; add `--no-start-reset` if that reset must not occur. Arguments other than the two install/uninstall options are retained in `ExecStart`.

To change saved settings, run the script normally under the same user account and use the interface, or edit `~/.config/follow_me/settings.json`. The installed service uses its own script and file copies under `~/.local/share/follow_me/`. On multiple computers, install the service separately on each machine after copying the script, model and, if used, language file; each service, dependency, camera device and NixOS configuration is local to that machine. Settings remain in the relevant user s home directory.

Uninstallation removes the systemd unit, but the code keeps `~/.local/share/follow_me/` and the settings file. Remove these manually if you also want to delete the copied files.

### Troubleshooting and Limitations

- **Camera or controls missing:** inspect paths with `ls -l /dev/v4l/by-id/`, controls with `v4l2-ctl --device PATH --list-ctrls`, and user permissions. Available controls and modes depend on the driver.
- **No detection:** check that `face_detection_yunet_2023mar.onnx` exists beside the script and is not an incomplete file. `--model PATH` selects another path.
- **Preview unavailable:** check DISPLAY/WAYLAND_DISPLAY and the OpenCV graphics backend; use `--no-tray` to avoid the KDE/Plasma StatusNotifier check.
- **Camera busy:** only one application may be able to open the physical camera at a time. To distribute a copy, configure `v4l2loopback` and select that device in the receiving application.
- **Axis moves the wrong way:** adjust pan and tilt inversion independently in settings or using the CLI options above.
- **Reset:** the startup reset moves the camera; clear its travel path. Use `--no-start-reset` to disable it. Recentering after target loss is separate and can be configured with `--lost-recenter`.

Compatibility of a camera, loopback device or system profile must be checked on the target machine; the script cannot guarantee a hardware control or kernel module is available.

### License

The original README states an intention to publish under GNU GPL v3 and says an official full-text `LICENSE` file should be added to the repository. Verify the presence and contents of the license before redistribution. The project license does not determine the licenses of the YuNet model or third-party dependencies.

---

## Français <a id="francais"></a>

### Démarrage rapide / Quick Start

1. **Préparez les fichiers.** Placez `linux_motorized_camera_driver.py` et `camera_driver.lng` dans le même dossier. Téléchargez également `face_detection_yunet_2023mar.onnx` dans ce dossier (le script a besoin de ce modèle) :

   ```sh
   curl -L -o face_detection_yunet_2023mar.onnx \
     https://huggingface.co/opencv/face_detection_yunet/resolve/main/face_detection_yunet_2023mar.onnx
   ```
2. **Dépendances.** Sous NixOS, lancez `python3` ; s’il manque des dépendances requises et que `nix-shell` est disponible, le script prépare et utilise automatiquement son shell Nix temporaire. Sous Debian/Ubuntu, installez vous-même les dépendances (voir [Prérequis](#prerequis)).
3. **Vérifiez la ligne de commande, puis testez.** Cette vérification rapide ne fait pas bouger la caméra :

   ```sh
   python3 linux_motorized_camera_driver.py --help
   ```

   Pour essayer le suivi sur la caméra détectée sans reset matériel au démarrage ni icône de notification :

   ```sh
   python3 linux_motorized_camera_driver.py --no-tray --no-start-reset
   ```

   N’ajoutez `--preview` que dans une session graphique. Pour choisir une caméra précise, passez `--device /dev/v4l/by-id/VOTRE-PERIPHERIQUE-video-index0`. Le script utilise les contrôles caméra V4L2 ; vérifiez les droits et le matériel avant utilisation. Le modèle, la caméra et les dépendances nécessaires doivent être disponibles pour le suivi.

### Fonctionnalités

- Détection YuNet avec `cv2.FaceDetectorYN` et suivi du visage.
- Commande des axes PTZ, avec zone morte, lissage, réglage de vitesse, inversion des axes et limite de correction.
- Reset matériel pan/tilt au lancement et recentrage logiciel après perte de cible, réglés séparément.
- Zoom automatique lorsque disponible. Le script exploite un contrôle de zoom V4L2 s’il est utilisable et peut employer un zoom numérique de repli ; ce dernier est un recadrage, pas un zoom optique.
- Mode graphique : icône de notification, démarrage/arrêt du suivi, aperçu, réglages, pilotage manuel et reset pan/tilt.
- Mode terminal sans icône, avec aperçu graphique facultatif.
- Option VirtualVideo pour transmettre une copie du flux à un périphérique `v4l2loopback` via `ffmpeg`.
- Sur NixOS, relance automatique dans un shell Nix intégré si des prérequis manquent et si `nix-shell` est disponible. Sur Debian et distributions dérivées, les dépendances manquantes sont signalées, sans installation automatique.

### Prérequis <a id="prerequis"></a>

#### Obligatoires pour le suivi

- Linux et Python 3 (Python 3.9 ou supérieur est recommandé ; le code utilise `argparse.BooleanOptionalAction`).
- Une caméra accessible par le script, avec commandes PTZ V4L2 adaptées. Le script détecte par défaut les nœuds `/dev/v4l/by-id/*-video-index*` ; `--device` permet d’en choisir un explicitement.
- OpenCV avec `cv2.FaceDetectorYN` (le contrôle du script indique qu’une version avec YuNet, au moins OpenCV 4.5.4, est nécessaire) et NumPy.
- Le modèle YuNet `face_detection_yunet_2023mar.onnx`.
- `v4l-utils`, qui fournit `v4l2-ctl`, requis pour les resets et les commandes de contrôle caméra.
- Les droits de lecture/écriture sur le périphérique vidéo. Selon la distribution, l’accès peut nécessiter l’appartenance au groupe `video` et une nouvelle ouverture de session.

Le script demande une capture de **640 × 480 à 30 images/s** par défaut. La résolution acceptée est limitée à 640 × 480 maximum ; la caméra doit néanmoins accepter le mode demandé.

#### Fonctions graphiques et vidéo virtuelle

- Le mode d’icône/réglages utilise Tkinter, Pillow, `pystray` et un environnement de bureau. Le contrôle tray du script vérifie DBus, Plasma/KDE et le service StatusNotifierWatcher. `--no-tray` permet de ne pas lancer ce mode.
- `--preview` nécessite un environnement graphique (DISPLAY ou WAYLAND_DISPLAY), Tkinter, Pillow et une version d’OpenCV compilée avec backend GTK ou Qt ; sans icône, le mode aperçu console s’ouvre aussi dans une fenêtre Tk.
- VirtualVideo requiert un module noyau `v4l2loopback` chargé avec un périphérique configuré, ainsi que `ffmpeg`. La compatibilité du module avec le noyau sélectionné n’est pas garantie par le script.

### Modèle YuNet

Le script ne contient pas le modèle ONNX. Téléchargez-le dans le même répertoire que le script (ou fournissez son emplacement avec `--model`) :

```sh
curl -L -o face_detection_yunet_2023mar.onnx \
  https://huggingface.co/opencv/face_detection_yunet/resolve/main/face_detection_yunet_2023mar.onnx
```

Le modèle et ses conditions de redistribution sont distincts du code et de ses dépendances ; consultez sa source avant de le redistribuer.

### Installation et premier lancement

Placez `linux_motorized_camera_driver.py` et le modèle dans un répertoire accessible. Il est recommandé de choisir un chemin stable pour la caméra :

```sh
ls -l /dev/v4l/by-id/
v4l2-ctl --device /dev/v4l/by-id/VOTRE-PERIPHERIQUE-video-index0 --list-ctrls
python3 linux_motorized_camera_driver.py \
  --device /dev/v4l/by-id/VOTRE-PERIPHERIQUE-video-index0 \
  --no-reset --max-delta 200 --preview
```

`--no-reset` désactive le recentrage logiciel initial après réception de la première image ; il **ne** désactive **pas** le reset matériel pan/tilt au démarrage. Pour supprimer ce mouvement au lancement, ajoutez `--no-start-reset`. `--no-start-reset` et `--no-reset` ont donc des effets différents.

À l’acquisition de la première image, le programme ignore 12 images pour laisser l’exposition se stabiliser. Arrêt : `Ctrl+C` en mode terminal ou touche `q` avec l’aperçu console ; dans l’interface, utilisez Quitter ou fermez l’application. Pour voir la syntaxe et les valeurs par défaut :

```sh
python3 linux_motorized_camera_driver.py --help
```

#### NixOS

Lancez le script avec `python3`. Si les prérequis examinés manquent et que `nix-shell` est disponible, il écrit un `shell.nix` temporaire, puis relance le script dans ce shell avec les paquets nécessaires (OpenCV avec GTK, NumPy, pystray, Pillow, Tkinter, PyGObject, `v4l-utils` et bibliothèques graphiques ; `ffmpeg` est ajouté si VirtualVideo est demandée). Cette relance automatique est protégée contre les boucles.

Le shell intégré évalue `import <nixpkgs> {}` : la sélection de nixpkgs dépend donc de la configuration Nix active sur cette machine (canal, flake/profile ou environnement Nix disponible). Il comprend aussi `ffmpeg`. Il ne faut pas supposer que deux ordinateurs ou profils disposent des mêmes paquets ou du même noyau. Testez le script et les attributs NixOS sur chaque configuration cible ; le script ne configure pas le module noyau `v4l2loopback`.

#### Debian, Ubuntu et dérivées

Aucune installation de dépendances n’est effectuée par le script. Le message de diagnostic suggère cette commande, à adapter aux fonctions utilisées :

```sh
sudo apt install python3-opencv python3-numpy v4l-utils ffmpeg python3-pil python3-tk python3-pystray
```

La version d’OpenCV du système doit effectivement fournir `FaceDetectorYN` ; la présence de `python3-opencv` seule ne garantit pas cette capacité. `ffmpeg` est nécessaire au partage VirtualVideo, et Pillow/Tkinter/pystray servent à l’interface.

### Réglages, langue et inversion des axes

En mode tray, ouvrez **Réglages** depuis le menu de l’icône. Les commandes et réglages disponibles comprennent le lancement/arrêt du suivi, le zoom automatique, l’aperçu, VirtualVideo, le pilotage manuel et le reset pan/tilt. Le panneau permet de régler le zoom maximal, la taille cible du visage, la vitesse, les zones mortes horizontale et verticale, l’aperçu, la langue et l’inversion des axes.

Par défaut, **pan** n’est pas inversé et **tilt** est inversé. Pour corriger une direction contraire à celle attendue :

- dans le panneau, cochez/décochez **Inverser gauche/droite (pan)** et **Inverser haut/bas (inclinaison)** ;
- ou en ligne de commande, utilisez `--invert-pan` pour inverser gauche/droite et `--no-invert-tilt` pour désactiver l’inversion haut/bas par défaut. `--invert-tilt` permet explicitement de l’activer.

Les réglages de l’interface sont sauvegardés dans :

```text
~/.config/follow_me/settings.json
```

Le fichier est créé lors de l’enregistrement des réglages. Il est propre au compte utilisateur et n’est pas situé dans le store Nix ; une reconstruction NixOS ne le remplace pas. En mode `--no-tray`, le script ne charge pas ce panneau de réglages : utilisez alors les options CLI.

#### Langue de l’interface

Les textes d’interface sont lus depuis `camera_driver.lng`, placé **à côté du script**. Ce fichier est au format INI et contient les sections `[en]` et `[fr]`. Le code utilise d’abord le texte de la langue sélectionnée, puis le texte anglais correspondant, et enfin l’identifiant de clé si aucune traduction n’est disponible. La langue choisie dans Réglages est enregistrée sous `language` dans `settings.json` et ne s’applique qu’après redémarrage.

Pour une installation de service, le programme copie `camera_driver.lng` à côté de la copie du script si le fichier est présent lors de l’installation. Les changements ultérieurs au fichier source ne mettent pas à jour cette copie de service : réinstallez le service pour actualiser son ensemble de fichiers.

### Toutes les options de la ligne de commande

Les options ci-dessous sont celles déclarées par `argparse` dans le script fourni. Les paramètres numériques ont des contrôles de validité ; les valeurs par défaut sont indiquées lorsque le code en définit une.

| Option | Valeur par défaut / effet |
|---|---|
| `-h`, `--help` | Affiche l’aide et quitte. |
| `-d`, `--device CHEMIN` | Nœud V4L2 à utiliser ; sinon sélection automatique. |
| `--model CHEMIN` | Chemin du modèle ONNX ; par défaut le fichier YuNet attendu à côté du script. |
| `--width N` | Largeur de capture, défaut `640`, entre 1 et 640. |
| `--height N` | Hauteur de capture, défaut `480`, entre 1 et 480. |
| `--fps N` | Images par seconde demandées, défaut `30`, minimum 1. |
| `--detect-every N` | Intervalle de détection, défaut `2`, minimum 1. |
| `--score N` | Seuil de détection, défaut `0.5`, strictement supérieur à 0 et au plus 1. |
| `--smooth N` | Lissage du suivi, défaut `0.6`, strictement supérieur à 0 et au plus 1. |
| `--deadzone X Y` | Zone morte horizontale et verticale, défaut `16 12` ; nombres positifs ou nuls. |
| `--kp-pan N` | Gain pan, défaut `6.0` ; nombre positif ou nul. |
| `--kp-tilt N` | Gain tilt, défaut `4.5` ; nombre positif ou nul. |
| `--invert-pan` | Inverse le sens gauche/droite ; désactivé par défaut. |
| `--invert-tilt`, `--no-invert-tilt` | Active/désactive l’inversion haut/bas ; activée par défaut. |
| `--no-start-reset` | Ne pas envoyer les commandes matérielles `pan_reset`/`tilt_reset` au lancement. |
| `--motor-interval N` | Intervalle moteur, défaut `0.06` seconde ; positif ou nul. |
| `--max-delta N` | Correction maximale par axe et commande, défaut `1000.0` ; strictement positif. |
| `--lost-recenter N` | Secondes avant recentrage après perte de cible, défaut `3.0` ; `0` désactive ce recentrage. |
| `--frame-timeout N` | Délai d’attente d’une nouvelle image, défaut `5.0` secondes ; strictement positif. |
| `--no-auto-zoom` | Désactive le zoom automatique, actif par défaut. |
| `--zoom-target-ratio N` | Rapport cible largeur du visage / largeur de l’image, défaut `0.25`, strictement entre 0 et 1. |
| `--zoom-max N` | Facteur maximal de zoom numérique, défaut `3.0`, minimum 1. |
| `--zoom-step N` | Pas maximal par commande pour un zoom matériel ; défaut automatique de 3 pas du contrôle caméra. Doit être strictement positif si fourni. |
| `--preview` | Active l’aperçu vidéo ; requiert un environnement graphique. |
| `--virtual-video` | Demande la copie du flux vers un périphérique `v4l2loopback`. |
| `--virtual-device CHEMIN` | Nœud loopback à utiliser ; détection automatique sinon. Le chemin fourni doit être reconnu comme `v4l2loopback`. |
| `--no-tray` | Mode terminal sans icône ni panneau de réglages. |
| `--no-reset` | Désactive le recentrage logiciel après la première image ; le reset matériel de démarrage reste indépendant. |
| `--install-service` | Installe, active et démarre un service systemd utilisateur, en conservant les autres arguments CLI dans la commande du service. |
| `--uninstall-service` | Arrête/désactive et supprime l’unité systemd utilisateur ; conserve les fichiers de l’application et les réglages. |

Options utiles en terminal :

```sh
# Sans icône ni aperçu ; reset matériel de démarrage désactivé
python3 linux_motorized_camera_driver.py --no-tray --no-start-reset

# Aperçu console (fenêtre graphique) sans icône de notification
python3 linux_motorized_camera_driver.py --no-tray --preview

# Sens pan inversé et inversion tilt désactivée
python3 linux_motorized_camera_driver.py --invert-pan --no-invert-tilt
```

### Partage du flux avec VirtualVideo

Le partage est désactivé par défaut. Activez-le avec `--virtual-video` ou dans le menu tray. Le script conserve la caméra physique ouverte pour le suivi et le pilotage PTZ, puis écrit une copie des images dans le nœud `v4l2loopback`. Les autres applications doivent choisir **la caméra virtuelle**, pas la caméra physique. La copie ne libère donc pas la caméra d’origine.

Exemple de configuration NixOS à adapter à la version de nixpkgs et au noyau sélectionné :

```nix
{ config, ... }:
{
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="CamPartagee" exclusive_caps=1
  '';
}
```

L’attribut de paquet peut ne pas exister pour chaque noyau/canal. Vérifiez qu’il est disponible et compatible avant d’ajouter cet extrait. Après configuration, reconstruisez/redémarrez pour charger le module. À titre temporaire, le script donne aussi la commande `sudo modprobe` adaptée à l’exemple (périphérique 10). Le module doit être chargé avant la session graphique et le service Follow Me. Il faut également les droits utilisateur sur le nœud vidéo, souvent via le groupe `video`.

Le nœud loopback est détecté automatiquement ; imposez-en un reconnu avec `--virtual-device /dev/videoN`. Exemple :

```sh
python3 linux_motorized_camera_driver.py --virtual-video --virtual-device /dev/video10
v4l2-ctl --list-devices
```

Si aucun loopback n’est détecté, le suivi continue mais le flux n’est pas partagé. Si `ffmpeg` manque ou si la sortie ne peut pas être ouverte, un avertissement est affiché et la sortie vidéo peut être désactivée. Avec `exclusive_caps=1`, attendez le message « VirtualVideo active » avant de sélectionner la caméra virtuelle dans l’autre application ; celle-ci peut devoir actualiser sa liste de caméras. Le détail dépend de l’application, du pilote et des permissions de la session.

### Installer comme service systemd utilisateur

L’installation copie le script dans `~/.local/share/follow_me/` sous le nom `follow_me_7.py`, copie le modèle YuNet et `camera_driver.lng` s’ils sont présents à côté du script, puis crée `~/.config/systemd/user/follow-me.service`. Elle exécute `systemctl --user daemon-reload`, active et démarre l’unité. Le service est rattaché à `graphical-session.target` et redémarre en cas d’échec.

Sur NixOS, le script installe aussi le `shell.nix` intégré dans ce répertoire et la commande du service passe par `nix-shell`. Sur les autres systèmes, l’unité utilise l’interpréteur Python courant lors de l’installation. La session graphique et les droits caméra doivent être disponibles pour le service utilisateur.

```sh
# Installer et démarrer avec les options indiquées (elles sont inscrites au service)
python3 linux_motorized_camera_driver.py --install-service --no-tray --no-reset --max-delta 200

# Vérifier l’état et consulter les journaux
systemctl --user status follow-me
journalctl --user -u follow-me -f

# Désinstaller l’unité
python3 linux_motorized_camera_driver.py --uninstall-service
```

`--no-reset` dans cet exemple désactive le recentrage logiciel, pas le reset matériel initial ; ajoutez `--no-start-reset` si ce reset ne doit pas avoir lieu. Les arguments autres que les deux options d’installation/désinstallation sont conservés dans `ExecStart`.

Pour changer les réglages sauvegardés, lancez le script normalement dans le même compte utilisateur et utilisez l’interface, ou modifiez `~/.config/follow_me/settings.json`. Le service installé utilise sa propre copie de script et de fichiers à `~/.local/share/follow_me/`. Sur plusieurs ordinateurs, installez le service séparément sur chaque machine après avoir copié le script, le modèle et, si utilisé, le fichier de langue ; chaque service, dépendance, périphérique caméra et configuration NixOS est local à la machine. Le fichier de réglages demeure dans le home de l’utilisateur concerné.

La désinstallation supprime l’unité systemd, mais le code conserve le répertoire `~/.local/share/follow_me/` et le fichier de réglages. Supprimez ces éléments manuellement si vous souhaitez aussi retirer les fichiers copiés.

### Dépannage et limites

- **Caméra ou commandes manquantes :** contrôlez les chemins `ls -l /dev/v4l/by-id/`, les commandes avec `v4l2-ctl --device CHEMIN --list-ctrls` et les droits de l’utilisateur. Les contrôles et modes disponibles dépendent du pilote.
- **Aucune détection :** vérifiez que `face_detection_yunet_2023mar.onnx` existe à côté du script et qu’il n’est pas remplacé par un fichier incomplet. `--model CHEMIN` permet de préciser un autre chemin.
- **Aperçu indisponible :** vérifiez DISPLAY/WAYLAND_DISPLAY et le backend graphique d’OpenCV ; utilisez `--no-tray` pour éviter le contrôle StatusNotifier de KDE/Plasma.
- **Caméra occupée :** une seule application peut être en mesure d’ouvrir la caméra physique à la fois. Pour distribuer une copie, configurez `v4l2loopback` et sélectionnez ce périphérique dans l’application destinataire.
- **Axe dans le mauvais sens :** ajustez l’inversion pan et tilt indépendamment dans les réglages ou via les options CLI décrites plus haut.
- **Réinitialisation :** le reset initial déplace la caméra ; dégagez son débattement. Utilisez `--no-start-reset` pour le désactiver. Le recentrage après perte de cible est un comportement distinct, réglable par `--lost-recenter`.

La compatibilité d’une caméra, d’un périphérique loopback ou d’un profil système donné doit être vérifiée sur la machine cible ; le script ne peut garantir la disponibilité d’un contrôle matériel ni la compatibilité d’un module noyau.

### Licence

Le README d’origine annonce une intention de publication sous GNU GPL v3 et précise qu’un fichier `LICENSE` contenant le texte intégral officiel doit être ajouté au dépôt. Vérifiez la présence et le contenu de la licence avant toute redistribution. Cette licence de projet ne détermine pas les licences du modèle YuNet ou des dépendances tierces.
