package;

import kha.math.Matrix3;
import kha.math.Vector2;
import kha.Window;

class Scaler {
    var stage:Stage;

    public var offset:Vector2;
    public var scale:Float;
    public var transform:Matrix3;


    public function new(stage:Stage) {
        this.stage = stage;

        offset = new Vector2();
        transform = Matrix3.identity();

        var window = Window.get(0);
        update(window.width, window.height);
        window.notifyOnResize(update);
    }


    public inline function unscaleX(x:Float) return (x - offset.x) / scale;
    public inline function unscaleY(y:Float) return (y - offset.y) / scale;


    function update(w:Int, h:Int) {
        var fx = w / stage.size.x,
            fy = h / stage.size.y;

        scale = Math.min(fx, fy);

        if (stage.pixelPerfect)
            scale = Math.max(1, Math.floor(scale));

        offset.x = 0.5 * (w - stage.size.x * scale);
        offset.y = 0.5 * (h - stage.size.y * scale);

        transform._00 = transform._11 = scale;
        transform._01 = transform._10 = transform._02 = transform._12 = 0.0;
        transform._20 = offset.x;
        transform._21 = offset.y;
        transform._22 = 1.0;
    }
}