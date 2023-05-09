package;

import kha.audio1.Audio;
import kha.Scheduler;
import kha.math.FastMatrix3;
import kha.Window;
import kha.Assets;
import kha.Framebuffer;
import kha.System;

#if kha_html5
import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
import kha.Macros;
#end

class Main {
	public static var instance:Main;

	var stage:Stage;
	var mouse:Dragger;
	var scale:Scaler;

	public function new(json:String) {
		Scheduler.addTimeTask(() -> {}, 0, 1/60); // mouse break on cpp without update method?
		System.notifyOnFrames((framebuffers) -> render(framebuffers[0]));

		stage = Stage.fromString(json);

		var w = Window.get(0);
		w.title = stage.name;
		w.resize(stage.windowSize.x, stage.windowSize.y);

		scale = new Scaler(stage);
		mouse = new Dragger(stage, scale);

		if (stage.data.bgm != "")
			Loader.loadSound(stage.data.bgm, snd -> Audio.play(snd, true));
	}


	function render(framebuffer: Framebuffer) {
		var g = framebuffer.g2;
		g.begin();
		g.imageScaleQuality = stage.pixelPerfect ? Low : High;
		g.pushTransformation(FastMatrix3.fromMatrix3(scale.transform));
		g.clear(stage.bgColor);
		stage.draw(g);
		g.popTransformation();
		g.end();
	}


	public static function main() {
		setFullWindowCanvas();
		
		System.start({title: "MousePSD", width: 400, height: 300}, (_) -> {
			var stageFile = "psd.stage";
#if cpp
			var args = Sys.args();
			if (args.length > 0) {
				stageFile = haxe.io.Path.join([args[0], stageFile]);
				Loader.prefix = haxe.io.Path.join([args[0], "res"]);
			} else {
				Loader.prefix = haxe.io.Path.directory(Sys.programPath());
				Loader.prefix = haxe.io.Path.join([Loader.prefix, "res"]);
			}
#end
			Assets.loadBlobFromPath(stageFile, b -> new Main(b.toString()));
		});
	}

	
	static function setFullWindowCanvas():Void {
		#if kha_html5
		document.documentElement.style.padding = "0";
		document.documentElement.style.margin = "0";
		document.body.style.padding = "0";
		document.body.style.margin = "0";
		final canvas:CanvasElement = cast document.getElementById(Macros.canvasId());
		canvas.style.display = "block";
		final resize = function() {
			var w = document.documentElement.clientWidth;
			var h = document.documentElement.clientHeight;
			if (w == 0 || h == 0) {
				w = window.innerWidth;
				h = window.innerHeight;
			}
			canvas.width = Std.int(w * window.devicePixelRatio);
			canvas.height = Std.int(h * window.devicePixelRatio);
			if (canvas.style.width == "") {
				canvas.style.width = "100%";
				canvas.style.height = "100%";
			}
		}
		window.onresize = resize;
		resize();
		#end
	}
}
