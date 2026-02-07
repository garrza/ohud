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

    // Draw a chevron spaceship at angle on a ring, facing clockwise
    // Minimal vertices (4 points) for stable rendering on low-res MIP display
    function drawArrowhead(dc as Graphics.Dc, cx as Number, cy as Number,
            radius as Number, angleDeg as Float, color as Number, size as Number) as Void {
        var posRad = Math.toRadians(angleDeg);

        // Ship center shifted slightly inward so outer wing stays in frame
        var r = radius - 3;
        var cX = cx + (r * Math.cos(posRad)).toNumber();
        var cY = cy - (r * Math.sin(posRad)).toNumber();

        // Heading: tangent clockwise (angleDeg - 90)
        var fwdRad = Math.toRadians(angleDeg - 90.0);
        var bkRad  = Math.toRadians(angleDeg + 90.0);
        var outRad = Math.toRadians(angleDeg);
        var inRad  = Math.toRadians(angleDeg + 180.0);

        var s = size.toFloat();

        // Nose tip
        var nX = cX + (0.5*s*Math.cos(fwdRad)).toNumber();
        var nY = cY - (0.5*s*Math.sin(fwdRad)).toNumber();

        // Outer wing tip (swept back, wide)
        var owX = cX + (0.3*s*Math.cos(bkRad) + 0.45*s*Math.cos(outRad)).toNumber();
        var owY = cY - (0.3*s*Math.sin(bkRad) + 0.45*s*Math.sin(outRad)).toNumber();

        // Inner wing tip
        var iwX = cX + (0.3*s*Math.cos(bkRad) + 0.45*s*Math.cos(inRad)).toNumber();
        var iwY = cY - (0.3*s*Math.sin(bkRad) + 0.45*s*Math.sin(inRad)).toNumber();

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        // Chevron: nose to each wing tip
        dc.drawLine(nX, nY, owX, owY);
        dc.drawLine(nX, nY, iwX, iwY);
    }
}
