package;

import kha.audio1.Audio;
import kha.Scheduler;
import kha.math.FastMatrix3;
import kha.Window;
import kha.Assets;
import kha.Framebuffer;
import kha.System;
import haxe.io.Path;

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

		if (Loader.loading) {
			var ww = System.windowWidth(), wh = System.windowHeight(),
				sz = 0.9 + 0.1 * Math.sin(System.time * 7),
				bl = 0.5 + 0.5 * Math.sin(System.time * 4),
				tm = FastMatrix3.scale(sz, sz).multmat(FastMatrix3.rotation(System.time * 3));
			tm._20 = ww - 22;
			tm._21 = wh - 22;
			g.pushTransformation(tm);
			g.color = kha.Color.fromFloats(bl, bl, bl, 0.45);
			g.fillRect(-15, -15, 30, 30);
			g.color = kha.Color.White;
		}
		g.end();
	}


	public static function main() {
		setFullWindowCanvas();
		
		System.start({title: "MousePSD", width: 400, height: 300}, (_) -> {
			var stageFile = "psd.stage";
#if cpp
			var args = Sys.args();
			if (args.length > 0) {
				stageFile = Path.join([args[0], stageFile]);
				Loader.prefix = Path.join([args[0], "res"]);
			} else {
				Loader.prefix = Path.directory(Sys.programPath());
				Loader.prefix = Path.join([Loader.prefix, "res"]);
			}
#elseif kha_html5
			Loader.prefix = "res";
			Loader.attempts = 3;
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
