# MousePSD

SOurce code of [MousePSD game engine](https://lampysprites.itch.io/mouse-psd). Please visit the linked page for a ready to use distribution of the program.

### Structure

- Runtime is a haxe/Kha program, which becomes the executable or js bundle.
- Exporter is a python program that processes resources and bundles them with brebuilt runtime files.

### Obtaining code
Recursive clone is important.
```sh
git clone --recursive --init ssh://git@github.com/lampysprites/mouse-psd
```

### Compiling runtimes
This project is build with Kha framework, and relies on its khamake capabilities. The commands below demonstrate its usage on windows.

HTML5 bundle
```sh
Kha\make.bat html5
copy build\html5 exporter\platforms\html5
```

Windows executable
```sh
Kha\make.bat windows --build --compile
copy build\windows exporter\platforms\windows
```

### Running the GUI

Installing dependencies:
```py
pip install -r requirements.txt
```

Launching:
```py
python mouse.py
```

- To run/build the user game with exporter, built artifacts must be placed into appropriate subfolder inside `platforms` folder.
- For audio compression to work, place ffmpeg executable into `tools` folder.