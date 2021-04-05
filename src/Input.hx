package src;

import js.Browser;

class Input {
    static var keysDown = new Map<String, Bool>();
    static var keysDownLast = new Map<String, Bool>();
    static var mouse = {
        x: 0,
        y: 0,
        dx: 0,
        dy: 0,
        currentButtons: 0,
        lastButtons: 0,
    }

    public static final LEFT = 1;
    public static final RIGHT = 2;
    public static final MIDDLE = 4;

    public static function setup() {
        // add all the event listeners for the different input methods
        // to the browser window for keyboard and mouse

        Browser.window.onkeydown = function (event: js.html.KeyboardEvent) {
            keysDown[event.key.toLowerCase()] = true;
        }

        Browser.window.onkeyup = function (event: js.html.KeyboardEvent) {
            keysDown.remove(event.key.toLowerCase());
        }

        Browser.window.onmousemove = function (event: js.html.MouseEvent) {
            mouse.x = event.offsetX;
            mouse.y = event.offsetY;
            mouse.dx = event.movementX;
            mouse.dy = event.movementY;
        }

        Browser.window.onmousedown = function (event: js.html.MouseEvent) {
            mouse.currentButtons = event.buttons;
        }

        Browser.window.onmouseup = function (event: js.html.MouseEvent) {
            mouse.currentButtons = event.buttons;
        }
    }

    public static function update() {
        keysDownLast.clear();
        for (key => value in keysDown) {
            keysDownLast[key] = value;
        }

        mouse.lastButtons = mouse.currentButtons;
        mouse.dx = 0;
        mouse.dy = 0;
    }

    public static function isKeyPressed(key: String) {
        return keysDown[key] && !keysDownLast[key];
    }

    public static function isKeyDown(key: String) {
        return keysDown[key];
    }

    public static function isKeyReleased(key: String) {
        return !keysDown[key] && keysDownLast[key];
    }

    public static function getMouseX(): Float { return mouse.x; }
    public static function getMouseY(): Float { return mouse.y; }
    public static function getMouseDeltaX(): Float { return mouse.dx; }
    public static function getMouseDeltaY(): Float { return mouse.dy; }

    static inline function checkForButton(btn: Int, total: Int) {
        return btn <= total;
    }

    public static function isMouseButtonDown(button: Int): Bool {
        return checkForButton(button, mouse.currentButtons);
    }

    public static function isMouseButtonPressed(button: Int): Bool {
        return checkForButton(button, mouse.currentButtons) && !checkForButton(button, mouse.lastButtons);
    }

    public static function isMouseButtonReleased(button: Int): Bool {
        return !checkForButton(button, mouse.currentButtons) && checkForButton(button, mouse.lastButtons);
    }
}
