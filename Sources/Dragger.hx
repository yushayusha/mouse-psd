package;

import kha.audio1.Audio;
import kha.Sound;
import kha.input.Mouse;
import kha.System;
using StringTools;

class Dragger {
    var stage:Stage;
    var offsetX:Int;
    var offsetY:Int;
    var layer:Layer;
    var scale:Scaler;
    var sfx:Sound;


    public function new(stage:Stage, scale:Scaler) {
        this.stage = stage;
        this.scale = scale;
        Mouse.get().notify(onDown, onUp, onMove);
        if (stage.data.sfx != "")
            Loader.loadSound(stage.data.sfx, snd -> sfx = snd);
    }


    public function unsubscribe() {
        Mouse.get().remove(onDown, onUp, onMove);
    }


    function onDown(b:Int, x:Int, y:Int) {
        if (b == 0 && layer == null) {
            x = Std.int(scale.unscaleX(x));
            y = Std.int(scale.unscaleY(y));

            layer = stage.pick(x, y);

            if (layer != null) {
                if (isLink(layer)) {
                    System.loadUrl(layer.name);
                    layer = null;

                } else {
                    offsetX = Std.int(x - layer.pos.x);
                    offsetY = Std.int(y - layer.pos.y);

                    if (sfx != null)
                        Audio.play(sfx);

                    stage.raise(layer);
                }
            }
            
		    kha.input.Mouse.get().setSystemCursor(Grabbing);
        }
    }


    function onUp(b:Int, x:Int, y:Int) {
        if (b == 0 && layer != null) {
            ensureInBounds(layer);

            if (sfx != null)
                Audio.play(sfx);

            layer = null;
		    kha.input.Mouse.get().setSystemCursor(Default);
        }
    }


    function onMove(x:Int, y:Int, dx:Int, dy:Int) {
        x = Std.int(scale.unscaleX(x));
        y = Std.int(scale.unscaleY(y));

        if (layer != null) {
            layer.pos.x = x - offsetX;
            layer.pos.y = y - offsetY;
        } else {
            var under = stage.pick(x, y),
                cursor = if (under == null) Default;
                    else if (isLink(under)) Pointer;
                    else Grab; 
		    kha.input.Mouse.get().setSystemCursor(cursor);
        }
    }


    function ensureInBounds(layer:Layer) {
        var xmin = scale.unscaleX(0), 
            xmax = scale.unscaleX(System.windowWidth()),
            ymin = scale.unscaleY(0),
            ymax = scale.unscaleY(System.windowHeight());
        
            if (layer.pos.x + layer.size.x < xmin || layer.pos.x > xmax ||
                    layer.pos.y + layer.size.y < ymin || layer.pos.y > ymax) {
                layer.pos.x = layer.data.pos[0];
                layer.pos.y = layer.data.pos[1];
            }
    }


    function isLink(layer:Layer) {
        return layer.name.startsWith("https://") || layer.name.startsWith("http://");
    }
}