import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module DrawUtils {

    // Draw a horizontal progress bar
    function drawProgressBar(dc as Graphics.Dc, x as Number, y as Number,
            w as Number, h as Number, pct as Float,
            fillColor as Number, bgColor as Number) as Void {
        // Background
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);
        // Fill
        var fillW = (w * pct).toNumber();
        if (fillW > w) { fillW = w; }
        if (fillW > 0) {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y, fillW, h);
        }
    }

    // Draw an annunciator status node
    function drawStatusNode(dc as Graphics.Dc, cx as Number, cy as Number,
            label as String, active as Boolean, activeColor as Number,
            dimColor as Number, badge as String?) as Void {
        var color = active ? activeColor : dimColor;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        // Draw small circle indicator
        var r = 4;
        if (active) {
            dc.fillCircle(cx, cy, r);
        } else {
            dc.drawCircle(cx, cy, r);
        }

        // Label below
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + r + 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        // Badge count if present
        if (badge != null && active) {
            dc.setColor(activeColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + r + 2, cy - r - 2, Graphics.FONT_XTINY, badge, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // Draw a triangular arrowhead at angle on a ring
    function drawArrowhead(dc as Graphics.Dc, cx as Number, cy as Number,
            radius as Number, angleDeg as Float, color as Number, size as Number) as Void {
        var angleRad = Math.toRadians(angleDeg);
        // Tip point on the ring
        var tipX = cx + (radius * Math.cos(angleRad)).toNumber();
        var tipY = cy - (radius * Math.sin(angleRad)).toNumber();

        // Two base points slightly behind the tip, offset perpendicular
        var backAngle = Math.toRadians(angleDeg + 180);
        var perpAngle1 = Math.toRadians(angleDeg + 90);
        var perpAngle2 = Math.toRadians(angleDeg - 90);

        var baseX = tipX + (size * Math.cos(backAngle)).toNumber();
        var baseY = tipY - (size * Math.sin(backAngle)).toNumber();

        var halfSize = size / 2;
        var pts = [
            [tipX, tipY],
            [baseX + (halfSize * Math.cos(perpAngle1)).toNumber(),
             baseY - (halfSize * Math.sin(perpAngle1)).toNumber()],
            [baseX + (halfSize * Math.cos(perpAngle2)).toNumber(),
             baseY - (halfSize * Math.sin(perpAngle2)).toNumber()]
        ];

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts as Array< Array<Number> >);
    }
}
