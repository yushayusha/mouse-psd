package;

import haxe.io.Path;
import kha.Sound;
import kha.Assets;
import kha.Image;

using Lambda;


class Loader {
	public static var prefix = "";
	public static var attempts = 1;
	public static var loading(get, null):Bool;

	static var loadingImages:Map<String, Array<Image->Void>> = [];
	static var loadedImages:Map<String, Image> = [];


	public static function loadImage(filename:String, done:Image->Void, ?tries:Int=-1) {
		if (prefix != "" && !Path.isAbsolute(filename))
			filename = Path.join([prefix, filename]);

		if (tries < 0)
			tries = attempts;
		
		if (loadedImages.exists(filename)) {
			done(loadedImages[filename]);
		} else if (loadingImages.exists(filename)) {
			loadingImages[filename].push(done);
		} else {
			loadingImages[filename] = [done];

			Assets.loadImageFromPath(filename, true, img -> {
				loadedImages[filename] = img;

				if (loadingImages.exists(filename)) {
					for (donest in loadingImages[filename])
						donest(img);
					loadingImages.remove(filename);
				}
			}, err -> {
				if (tries > 0) {
					trace('retry loading $filename');
					loadImage(filename, _ -> {}, tries - 1);
				} else {
					trace('failed to load $filename');
					loadingImages.remove(filename);
				}
			});
		}
	}


	static var loadingSounds:Map<String, Array<Sound->Void>> = [];
	static var loadedSounds:Map<String, Sound> = [];

	public static function loadSound(filename:String, done:Sound->Void, ?tries:Int=-1) {
		if (prefix != "" && !Path.isAbsolute(filename))
			filename = Path.join([prefix, filename]);

		if (tries < 0)
			tries = attempts;

		if (loadedSounds.exists(filename)) {
			done(loadedSounds[filename]);
		} else if (loadingSounds.exists(filename)) {
			loadingSounds[filename].push(done);
		} else {
			loadingSounds[filename] = [done];

			Assets.loadSoundFromPath(filename, snd -> {
				snd.uncompress(() -> {
					loadedSounds[filename] = snd;

					if (loadingSounds.exists(filename)) {
						for (donest in loadingSounds[filename])
							donest(snd);
						loadingSounds.remove(filename);
					}
				});
			},	err -> {
				if (tries > 0) {
					trace('retry loading $filename');
					loadSound(filename, _ -> {}, tries - 1);
				} else {
					trace('failed to load $filename');
					loadingSounds.remove(filename);
				}
			});
		}
	}


	static function get_loading() {
		var loaded = !(loadedImages.empty() && loadedSounds.empty()),
			remains = !(loadingImages.empty() && loadingSounds.empty());
		return !loaded && remains;
	}
}
