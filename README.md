# MousePSD

SOurce code of [MousePSD game engine](https://lampysprites.itch.io/mouse-psd). Please visit the linked page for a ready to use distribution of the program.

### Structure

- Exporter GUI is a python program that processes resources and bundles them with runtime files.
- Runtime, needed to run or export the project, is an executable (or js bundle) that is built separately.
- Audio encoding is done with FFmpeg, whose executable should be placed into `tools/` subfolder.

### Obtaining code
Unless you have Kha set up somewhere else (eg vscode extension), use recursive clone:
```sh
git clone --recursive --init --depth 1 ssh://git@github.com/lampysprites/mouse-psd
# if windows
mouse-psd\Kha\get_dlc.bat
# if linux or macox
./mouse-psd/Kha/get_dlc
```

### Running exporter

Requires [python3](https://python.org).

```py
pip install -r requirements.txt
python mouse.py
```

### Compiling runtimes
This project is build with [Kha framework](https://github.com/Kode/Kha), and relies on its khamake capabilities. The commands below demonstrate its usage on windows.

HTML5 bundle (for export):
```sh
Kha\make.bat html5
copy build\html5 exporter\platforms\html5
```

Windows executable (for run and export):
```sh
Kha\make.bat windows --build --compile
copy build\windows exporter\platforms\windows
```


### Compiling your project

There's a way to build the game as Kha project for [a wider range of platforms](https://github.com/kode/kha#supported-platforms) that do not use simple export, or add some custom logic to it. To do that, place the exported assets into a new folder inside the repo (say, `Assets`) and add following line to `khafile.js`:

```js
// const project = ... /* after this line */
project.addAssets('Assets/**'); /* name of assets folder */
// resolve(project) /* before this line*/
```