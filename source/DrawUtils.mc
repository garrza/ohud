import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module DrawUtils {

    // Draw a horizontal progress bar
    function drawProgressBar(dc as Graphics.Dc, x as Number, y as Number,
            w as Number, h as Number, pct as Float,
            fillColor as Number, bgColor as Number) as Void {
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);
        var fillW = (w * pct).toNumber();
        if (fillW > w) { fillW = w; }
        if (fillW > 0) {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y, fillW, h);
        }
    }

    // Draw a spaceship at angle on a ring, facing clockwise (direction of travel)
    // Shape: elongated nose, swept delta wings, narrow tail fins, engine notch
    function drawArrowhead(dc as Graphics.Dc, cx as Number, cy as Number,
            radius as Number, angleDeg as Float, color as Number, size as Number) as Void {
        var posRad = Math.toRadians(angleDeg);

        // Ship center shifted slightly inward so outer wing stays in frame
        var r = radius - 4;
        var cX = cx + (r * Math.cos(posRad)).toNumber();
        var cY = cy - (r * Math.sin(posRad)).toNumber();

        // Heading: tangent clockwise (angleDeg - 90)
        var fwdRad = Math.toRadians(angleDeg - 90.0);
        var bkRad  = Math.toRadians(angleDeg + 90.0);
        var outRad = Math.toRadians(angleDeg);
        var inRad  = Math.toRadians(angleDeg + 180.0);

        var s = size.toFloat();

        // Nose tip (sharp point)
        var nX = cX + (0.6*s*Math.cos(fwdRad)).toNumber();
        var nY = cY - (0.6*s*Math.sin(fwdRad)).toNumber();

        // Outer shoulder (fuselage widens slightly before wings)
        var osX = cX + (0.15*s*Math.cos(fwdRad) + 0.12*s*Math.cos(outRad)).toNumber();
        var osY = cY - (0.15*s*Math.sin(fwdRad) + 0.12*s*Math.sin(outRad)).toNumber();

        // Outer wing tip (swept back, wide)
        var owX = cX + (0.2*s*Math.cos(bkRad) + 0.55*s*Math.cos(outRad)).toNumber();
        var owY = cY - (0.2*s*Math.sin(bkRad) + 0.55*s*Math.sin(outRad)).toNumber();

        // Outer wing trailing edge (narrows back)
        var otX = cX + (0.3*s*Math.cos(bkRad) + 0.15*s*Math.cos(outRad)).toNumber();
        var otY = cY - (0.3*s*Math.sin(bkRad) + 0.15*s*Math.sin(outRad)).toNumber();

        // Outer tail fin
        var ofX = cX + (0.55*s*Math.cos(bkRad) + 0.2*s*Math.cos(outRad)).toNumber();
        var ofY = cY - (0.55*s*Math.sin(bkRad) + 0.2*s*Math.sin(outRad)).toNumber();

        // Engine notch (concave tail center)
        var tX = cX + (0.35*s*Math.cos(bkRad)).toNumber();
        var tY = cY - (0.35*s*Math.sin(bkRad)).toNumber();

        // Inner tail fin
        var ifX = cX + (0.55*s*Math.cos(bkRad) + 0.2*s*Math.cos(inRad)).toNumber();
        var ifY = cY - (0.55*s*Math.sin(bkRad) + 0.2*s*Math.sin(inRad)).toNumber();

        // Inner wing trailing edge
        var itrX = cX + (0.3*s*Math.cos(bkRad) + 0.15*s*Math.cos(inRad)).toNumber();
        var itrY = cY - (0.3*s*Math.sin(bkRad) + 0.15*s*Math.sin(inRad)).toNumber();

        // Inner wing tip
        var iwX = cX + (0.2*s*Math.cos(bkRad) + 0.55*s*Math.cos(inRad)).toNumber();
        var iwY = cY - (0.2*s*Math.sin(bkRad) + 0.55*s*Math.sin(inRad)).toNumber();

        // Inner shoulder
        var isX = cX + (0.15*s*Math.cos(fwdRad) + 0.12*s*Math.cos(inRad)).toNumber();
        var isY = cY - (0.15*s*Math.sin(fwdRad) + 0.12*s*Math.sin(inRad)).toNumber();

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [nX,nY], [osX,osY], [owX,owY], [otX,otY], [ofX,ofY],
            [tX,tY],
            [ifX,ifY], [itrX,itrY], [iwX,iwY], [isX,isY]
        ]);
    }
}
