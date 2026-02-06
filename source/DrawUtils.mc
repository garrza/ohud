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

    // Draw a triangular arrowhead at angle on a ring
    function drawArrowhead(dc as Graphics.Dc, cx as Number, cy as Number,
            radius as Number, angleDeg as Float, color as Number, size as Number) as Void {
        var angleRad = Math.toRadians(angleDeg);
        var tipX = cx + (radius * Math.cos(angleRad)).toNumber();
        var tipY = cy - (radius * Math.sin(angleRad)).toNumber();

        var backAngle = Math.toRadians(angleDeg + 180);
        var perpAngle1 = Math.toRadians(angleDeg + 90);
        var perpAngle2 = Math.toRadians(angleDeg - 90);

        var baseX = tipX + (size * Math.cos(backAngle)).toNumber();
        var baseY = tipY - (size * Math.sin(backAngle)).toNumber();

        var halfSize = size / 2;
        var p1x = baseX + (halfSize * Math.cos(perpAngle1)).toNumber();
        var p1y = baseY - (halfSize * Math.sin(perpAngle1)).toNumber();
        var p2x = baseX + (halfSize * Math.cos(perpAngle2)).toNumber();
        var p2y = baseY - (halfSize * Math.sin(perpAngle2)).toNumber();

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(tipX, tipY, p1x, p1y);
        dc.drawLine(tipX, tipY, p2x, p2y);
        dc.drawLine(p1x, p1y, p2x, p2y);
    }
}
