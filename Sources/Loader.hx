package;

import kha.Sound;
import kha.Assets;
import kha.Image;


class Loader {
	public static var prefix = "";

	static var loadingImages:Map<String, Array<Image->Void>> = [];
	static var loadedImages:Map<String, Image> = [];


	public static function loadImage(filename:String, done:Image->Void) {
#if cpp
		if (prefix != "")
			filename = haxe.io.Path.join([prefix, filename]);
#end
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
			}, err -> trace(err));
		}
	}


	static var loadingSounds:Map<String, Array<Sound->Void>> = [];
	static var loadedSounds:Map<String, Sound> = [];

	public static function loadSound(filename:String, done:Sound->Void) {
#if cpp
		if (prefix != "")
			filename = haxe.io.Path.join([prefix, filename]);
#end

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
			}, err -> trace(err));
		}
	}
}
