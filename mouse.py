from psd_tools import PSDImage
from psd_tools.api.layers import Layer, Tag
import io
import FreeSimpleGUI as sg
import os
from os import path
from shutil import rmtree, copytree, copyfile
from secrets import token_hex
import subprocess
import json
import webbrowser
import math
import rectpack
import PIL

audio_types = (('Audio Files', '*.wav;*.mp3;*.ogg'), ('All Files', "*.*"))
psd_types = (('Peesdee Files', '*.psd'), ('All Files', "*.*"))

sg.theme('DarkGrey5')

platforms = []
buildf = path.join(path.dirname(__file__), 'build')

if path.exists(path.join(buildf, 'windows')):
    platforms.append('Windows')

if path.exists(path.join(buildf, 'html5')):
    platforms.append('HTML5')

platforms.append('Assets Only')


properties_window = [
            [sg.Text('Title', size=(11, 1)), sg.Input('MousePSD', key=':project', expand_x=True, tooltip='Used as window/page title, and executable name.')],
            [sg.Text('Window Size', size=(11, 1)), sg.Input('960x540', key=':size', expand_x=True, tooltip='Dimensions of the window. Does not affect asset size.')],
            [sg.Text('Background', size=(11, 1)), sg.Input('#333333', key=':background', expand_x=True, tooltip='Color of the area underneath and around the game stage.'), sg.ColorChooserButton('Choose...')],
            [sg.Checkbox('Pixel Perfect', key=':perfect', tooltip='Limit window scaling to times whole number, and disable scaling filter.')],
]

properties_audio = [
            [sg.Text('BGM', size=(15, 1)), sg.Input(key=':bgm', expand_x=True, tooltip='Background audio loop.'), sg.FilesBrowse('Open...', file_types=audio_types)],
            [sg.Text('BGM Volume', size=(15, 1)), sg.Slider(orientation='h', key=':bgmvol', expand_x=True, range=(10,200), default_value=100, resolution=5, disable_number_display=True, enable_events=True, tooltip='Adjust BGM volume.'), sg.Text('100%', size=(4, 1), justification='right', key=':bgmvol-display')],
            [sg.Text('SFX', size=(15, 1)), sg.Input(key=':sfx', expand_x=True, tooltip='Sound for picking and dropping things.'), sg.FilesBrowse('Open...', file_types=audio_types)],
            [sg.Text('SFX Volume', size=(15, 1)), sg.Slider(orientation='h', key=':sfxvol', expand_x=True, range=(10,200), default_value=100, resolution=5, disable_number_display=True, enable_events=True, tooltip='Adjust SFX volume.'), sg.Text('100%', size=(4, 1), justification='right', key=':sfxvol-display')],
            [sg.Text('Sound Compression', size=(15, 1)), sg.Slider(orientation='h', key=':sndqty', expand_x=True, range=(20,100), default_value=80, resolution=20, disable_number_display=True, enable_events=True, tooltip='Low values reduce the size, high values improve quality.'), sg.Text('0.8', size=(4, 1), justification='right', key=':sndqty-display')],

]

properties = [
    [sg.TabGroup([
        [sg.Tab('Window', properties_window), sg.Tab('Audio', properties_audio)]
    ])]
]

layout = [  [sg.Image(key=':preview', expand_x=True)],
            [sg.Input(key=':psd', visible=False, enable_events=True), sg.FileBrowse('Open...', file_types=psd_types, tooltip='Select PSD file to be used.'),
                sg.Push(),
                sg.DropDown(platforms, default_value=platforms[0], key=':platform', readonly=True, disabled=True, tooltip='Which platform the bundle is made for.'),
                sg.Button('Run', disabled=True, tooltip='Launch game.'),
                sg.Input(key=':export', visible=False, enable_events=True), sg.FolderBrowse('Export', disabled=True, button_color=('#ffffff', '#ff8000'), tooltip='Bundle game files for distribution.'),
            ],
            [sg.Column(properties, key=':properties', visible=False)],
            [sg.StatusBar('                                      ', relief='groove', key=':status')]
]

psd:PSDImage = None
status = ''
icon_b64 = b'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'
window = sg.Window('MousePSD', layout, icon=icon_b64)


def ui_lock_set(state):
    keys = [ 'Open...', 'Run', 'Export', ':platform', ]
    for key in keys:
        window[key].update(disabled=state)


def is_locked_layer(layer):
    blocks = layer._record.tagged_blocks
    lspf = blocks[Tag.PROTECTED_SETTING]
    return bool(lspf.data & 0x80000000)


def clean():
    temp = path.join(path.dirname(__file__), 'temp')
    if path.isdir(temp):
        rmtree(temp)


def preview():
    # create a preview
    prev = psd.composite()
    prev = prev.resize((int(prev.width / prev.height * 240), 240))
    # show preview
    bio = io.BytesIO()
    prev.save(bio, format='PNG')
    window[':preview'].update(data = bio.getvalue())
    col = ''.join(['#', *[hex(c)[2:] for c in prev.getpixel((0, 0))]])
    window[':background'].update(col)


def export_layer(layer):
    window.write_event_value(':set_status', f'Rendering layer {layer.name}...')
    img = layer.composite()

    return {
        'name': layer.name,
        'group': False,
        'image': img,
        'src': [0, 0],
        'size': [img.width, img.height],
        'pos': (layer.left, layer.top),
        'locked': is_locked_layer(layer),
    }


def to_size(s:str):
    vals = [int(tok) for tok in s.split('x', 1)]
    if len(vals) == 2 and all(vals):
        return vals
    return [800, 600]


def to_color(s:str):
    if s.startswith('#') and len(s) == 7:
        return s
    return '#000000'


def encode(values, fmt):
    ff = path.join(path.dirname(__file__), 'tools', 'ffmpeg.exe')

    qty = values[':sndqty']
    if qty > 80:
        qty = '320k'
    elif qty > 60:
        qty = '192k'
    elif qty > 40:
        qty = '128k'
    else:
        qty = '96k'

    bgmvol = values[':bgmvol']
    if bgmvol != 100:
        bgmvol = ['-filter:a', 'volume=' + str(bgmvol / 100)]
    else:
        bgmvol = []

    sfxvol = values[':sfxvol']
    if sfxvol != 100:
        sfxvol = ['-filter:a', 'volume=' + str(sfxvol / 100)]
    else:
        sfxvol = []

    if fmt == 'mp3':
        codec = 'libmp3lame'
        form = 'mp3'
        ext = '.mp3'
    else:
        codec = 'libvorbis'
        form = 'ogg'
        ext = '.ogg'


    if path.isfile(values[':bgm']):
        window.write_event_value(':set_status', 'Encoding BGM...')
        out = path.join(path.dirname(__file__), 'temp', 'res', 'bgm') + ext
        p = subprocess.Popen([ff, '-i', values[':bgm'], '-c:a', codec, *bgmvol, '-b:a', qty, '-f', form, out])
        p.wait()

    if path.isfile(values[':sfx']):
        window.write_event_value(':set_status', 'Encoding SFX...')
        out = path.join(path.dirname(__file__), 'temp', 'res', 'sfx') + ext
        p = subprocess.Popen([ff, '-i', values[':sfx'], '-c:a', codec, *sfxvol, '-b:a', qty, '-f', form, out])
        p.wait()

atlas_size_max = 2048

def save_atlas(records):
    window.write_event_value(':set_status', 'Packing atlas...')
    packer = rectpack.newPacker(rotation=False)
    area = 0
    for i, rec in enumerate(records):
        if rec['group']:
            for lr in rec['layers']:
                w, h = lr['size']
                if w < atlas_size_max and h < atlas_size_max:
                    area += w * h
                    packer.add_rect(w, h, lr)
                else:
                    fname = f'i{token_hex(12)}.png'
                    rec['image'].save(path.join(path.dirname(__file__), 'temp', 'res', fname), format='PNG', optimize=True)
                    rec['image'].close()
                    rec['image'] = fname
        else:
            w, h = rec['size']
            if w < atlas_size_max and h < atlas_size_max:
                area += w * h
                packer.add_rect(w, h, rec)
            else:
                fname = f'i{token_hex(12)}.png'
                rec['image'].save(path.join(path.dirname(__file__), 'temp', 'res', fname), format='PNG', optimize=True)
                rec['image'].close()
                rec['image'] = fname

    area = area * 1.33 # expect some empty space

    tx_size = 2 ** math.ceil(0.5 * math.log2(area))
    if tx_size < atlas_size_max:
        packer.add_bin(tx_size, tx_size)
    else:
        for _ in range(math.ceil(area / atlas_size_max ** 2)):
            packer.add_bin(tx_size, tx_size)

    packer.pack()

    window.write_event_value(':set_status', 'Rendering atlas...')

    for page in packer:
        tx = PIL.Image.new('RGBA', (page.width, page.height), '#00000000')
        fname = f'p{token_hex(12)}.png'

        for rect in page:
            rec = rect.rid
            rec['src'] = [rect.x, rect.y]
            tx.paste(rec['image'], rec['src'])
            rec['image'].close()
            rec['image'] = fname

        tx.save(path.join(path.dirname(__file__), 'temp', 'res', fname), format='PNG', optimize=True)
        tx.close()


def save_images(records):
    for rec in records:
        if rec['group']:
            save_images(rec['layers'])
        else:
            fname = f'i{token_hex(12)}.png'
            rec['image'].save(path.join(path.dirname(__file__), 'temp', 'res', fname), format='PNG', optimize=True)
            rec['image'].close()
            rec['image'] = fname


def export(values, audio='ogg', pack=False):
    # prepare export folder
    temp = path.join(path.dirname(__file__), 'temp')
    if path.isdir(temp):
        rmtree(temp)
    os.mkdir(temp)
    os.mkdir(path.join(temp, 'res'))

    ## Layers
    records = []

    layer:Layer
    for layer in psd:
        if layer.is_group() and not is_locked_layer(layer):
            layers = []

            for sub_layer in layer:
                record = export_layer(sub_layer)
                layers.append(record)

            records.append({
                'name': layer.name,
                'group': True,
                'layers': layers
            })
        else:
            record = export_layer(layer)
            records.append(record)

    if pack:
        save_atlas(records)
    else:
        save_images(records)

    ## Audio
    encode(values, audio)

    bgm = ''
    if values[':bgm']:
        if audio == 'ogg':
            bgm = 'bgm.ogg'
        elif audio == 'mp3':
            bgm = 'bgm.mp3'

    sfx = ''
    if values[':sfx']:
        if audio == 'ogg':
            sfx = 'sfx.ogg'
        elif audio == 'mp3':
            sfx = 'sfx.mp3'

    ## Write json
    window.write_event_value(':set_status', 'Encoding stage...')

    with io.open(path.join(temp, 'psd.stage'), 'w') as f:
        desc = {
            'name': values[':project'] or 'MousePSD',
            'size': [psd.width, psd.height],
            'window': to_size(values[':size']),
            'pixelPerfect': values[':perfect'],
            'background': to_color(values[':background']),
            'bgm': bgm,
            'sfx': sfx,
            'layers': records,
        }
        json.dump(desc, f)

    window.write_event_value(':set_status', '')


def open_psd(file):
    global psd

    ui_lock_set(True)
    window.write_event_value(':set_status', 'Opening file...')
    psd = PSDImage.open(file)
    window.write_event_value(':set_status', 'Rendering Preview...')
    preview()
    ui_lock_set(False)
    window.write_event_value(':set_status', '')


def export_dump(values):
    ui_lock_set(True)
    dest = values[':export']
    if not path.exists(dest):
        window.write_event_value(':set_status', 'Path does not exist: ' + dest)
        return

    clean()
    export(values, audio='ogg', pack=True)

    temp = path.join(path.dirname(__file__), 'temp')
    copytree(path.join(temp, 'res'), path.join(dest, 'res'), dirs_exist_ok=True)
    copyfile(path.join(temp, 'psd.stage'), path.join(dest, 'psd.stage'))

    ui_lock_set(False)
    window.write_event_value(':set_status', '')


def export_html(values):
    ui_lock_set(True)
    dest = values[':export']
    if not path.exists(dest):
        window.write_event_value(':set_status', 'Path does not exist: ' + dest)
        return

    clean()
    export(values, audio='mp3', pack=True)

    temp = path.join(path.dirname(__file__), 'temp')
    copytree(path.join(temp, 'res'), path.join(dest, 'res'), dirs_exist_ok=True)
    copyfile(path.join(temp, 'psd.stage'), path.join(dest, 'psd.stage'))

    files = ['index.html', 'favicon.ico', 'kha.js']
    for f in files:
        ff = path.join(buildf, 'html5', f)
        copyfile(ff, path.join(dest, f))

    ui_lock_set(False)
    window.write_event_value(':set_status', '')


def export_win32(values):
    ui_lock_set(True)
    dest = values[':export']
    if not path.exists(dest):
        window.write_event_value(':set_status', 'Path does not exist: ' + dest)
        return

    clean()
    export(values, audio='ogg', pack=True)

    temp = path.join(path.dirname(__file__), 'temp')
    copytree(path.join(temp, 'res'), path.join(dest, 'res'), dirs_exist_ok=True)
    copyfile(path.join(temp, 'psd.stage'), path.join(dest, 'psd.stage'))

    exe = path.join(buildf, 'windows', 'MousePSD.exe')
    copyfile(exe, path.join(dest, values[':project'] + '.exe'))

    ui_lock_set(False)
    window.write_event_value(':set_status', '')


def test(values):
    ui_lock_set(True)
    export(values, audio='ogg')
    exe = path.join(buildf, 'windows', 'MousePSD.exe')
    temp = path.join(path.dirname(__file__), 'temp')
    subprocess.Popen([exe, temp], creationflags=subprocess.DETACHED_PROCESS)
    ui_lock_set(False)


while True:
    event, values = window.read()
    if event == sg.WIN_CLOSED: # if user closes window or clicks cancel
        break

    if event == ':bgmvol':
        window[':bgmvol-display'].update(str(int(values[':bgmvol'])) + '%')
    if event == ':sfxvol':
        window[':sfxvol-display'].update(str(int(values[':sfxvol'])) + '%')
    if event == ':sndqty':
        window[':sndqty-display'].update(str(values[':sndqty'] / 100))

    if event == ':set_status':
        print(values[':set_status'])
        window[':status'].update(values[':set_status'])

    if event == ':opened':
        window[':properties'].update(visible=True)
        window[':size'].update(f'{psd.width}x{psd.height}')
        name = path.basename(values[':psd'])[:-4].capitalize()
        window[':project'].update(name)

    if event == ':psd':
        window[':properties'].update(visible=False)
        window.perform_long_operation(lambda: open_psd(values[':psd']), ':opened')

    if event == ':export':
        window[':status'].update('Preparing...')
        if values[':platform'] == 'HTML5':
            window.perform_long_operation(lambda: export_html(values), ':exported')
        elif values[':platform'] == 'Windows':
            window.perform_long_operation(lambda: export_win32(values), ':exported')
        elif values[':platform'] == 'Assets Only':
            window.perform_long_operation(lambda: export_dump(values), ':exported')

    if event == ':exported':
        webbrowser.open(values[':export'])

    if event == 'Run':
        window.perform_long_operation(lambda: test(values), ':runtest')


clean()

window.close()