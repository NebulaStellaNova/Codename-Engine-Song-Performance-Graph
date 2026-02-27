import funkin.options.Options;
import funkin.backend.MusicBeatGroup;

import flixel.text.FlxTextFormat;
import flixel.text.FlxTextFormatMarkerPair;

var frameDrops = [];

var bg = new FunkinSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);

var frames = data.frames;

var camera = new FlxCamera();

var frameObjs = new MusicBeatGroup();

var frameDataTxt:FunkinText;
var frameDataTxt2:FunkinText;
var continueTxt:FunkinText;
var sideTxt:FunkinText;

var selectedFrame = 0;

var width;

function postCreate() {
    camera.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(camera, false);

    bg.camera = camera;
    bg.screenCenter();
    bg.alpha = 0.75;
    bg.zoomFactor = 0;
    bg.scrollFactor.set();
    add(bg);

    frameObjs.camera = camera;
    add(frameObjs);

    width = 10;//Math.ceil(500/frames[frames.length-1].step);

    var prevRate = Options.framerate;

    var prevHeight = 0;

    for (i=>frame in frames) {
        var gradientPos = frame.rate / Options.framerate;
        var color = /* i % 2 == 0 ? FlxColor.WHITE : FlxColor.RED;  */FlxColor.interpolate(FlxColor.RED, FlxColor.GREEN, (gradientPos * 2) - 0.5);
        var g = new FunkinSprite(i * width, 0).makeGraphic(width, 200 * gradientPos, color);
        g.y = 200 - g.height;

        if (frame.isDrop) {
            frameDrops.push(frame.frame);
        }

        prevRate = frame.rate;
        frameObjs.add(g);

    }

    frameDataTxt = new FunkinText(0, 0, null, "You ended the song before the countdown ended :(");
    frameDataTxt.size = 30; 
    frameDataTxt.camera = camera;
    frameDataTxt.screenCenter();
    add(frameDataTxt);

    frameDataTxt2 = new FunkinText(0, 0, null, "");
    frameDataTxt2.size = 30; 
    frameDataTxt2.camera = camera;
    add(frameDataTxt2);
    
    frameObjs.screenCenter();
    
    continueTxt = new FunkinText(0, 0, null, "Press ACCEPT to continue.");
    continueTxt.size = 35;
    continueTxt.camera = camera;
    continueTxt.updateHitbox();
    continueTxt.screenCenter();
    continueTxt.y = FlxG.height - 100;
    continueTxt.borderSize = 2;
    continueTxt.scrollFactor.set();
    add(continueTxt);

    sideTxt = new FunkinText(0, 0, null, "");
    sideTxt.size = 20;
    sideTxt.camera = camera;
    sideTxt.updateHitbox();
    sideTxt.screenCenter();
    sideTxt.x = 10;
    sideTxt.borderSize = 2;
    sideTxt.scrollFactor.set();
    add(sideTxt);

    // trace(frameDrops);

    for (i in members) {
        if (i == bg) continue;
        i.alpha = 0;
        FlxTween.tween(i, {alpha: 1}, 0.5);
    }

    camera.zoom = 0.9;
    FlxTween.tween(camera, { zoom: 1 }, 0.5, { ease: FlxEase.sineOut });

    scroll(0);
}

var timer = 100;

var playedThisFrame = false;

function update() {
    playedThisFrame = false;

    if (FlxG.keys.justPressed.TAB && frameDrops.length != 0) {
        scroll(-1);
        var foundOne = false;
        while (!foundOne) {
            scroll(1);
            for (i in frameDrops) {
                if (i > frames[selectedFrame].frame) {
                    selectedFrame = getIndexByFrame(i);
                    foundOne = true;
                    break;
                }
            }
        }
        scroll(0);
    }
}

function postUpdate(elapsed) {
    frameDataTxt.alignment = "center";
    frameDataTxt2.alignment = "center";
    for (i=>frame in frameObjs.members) {
        frame.alpha = i == selectedFrame ? 1 : (0.4-(Math.abs(selectedFrame-i)/50));
        if (i != selectedFrame) continue;
        frameDataTxt.text = [
            "FRAMERATE: " + frames[i].rate,
            "< SONG STEP: " + frames[i].step + " >",
            "SONG BEAT: " + frames[i].beat,
            "v"
        ].join("\n");
        frameDataTxt.updateHitbox();
        frameDataTxt.x = frame.x + (frame.width/2) - (frameDataTxt.width/2);
        frameDataTxt.y = frame.y - frameDataTxt.height - 5;
        frameDataTxt2.text = "^\n FRAME: " + frames[i].frame;
        frameDataTxt2.updateHitbox();
        frameDataTxt2.x = frame.x + (frame.width/2) - (frameDataTxt2.width/2);
        frameDataTxt2.y = frame.y + frame.height + 5;
    }

    if (controls.RIGHT || controls.LEFT) {
        timer -= elapsed * 1000;
        if (timer < 1) scroll(controls.RIGHT ? 1 : -1);
    } else {
        timer = 500;
    }


    if (controls.RIGHT_P || FlxG.mouse.wheel > 0) {
        scroll(1);
    }
    if (controls.LEFT_P || FlxG.mouse.wheel < 0) scroll(-1);

    if (controls.ACCEPT) data.endSong();
}

function scroll(amt) {
    selectedFrame = FlxMath.wrap(selectedFrame + amt, 0, frames.length-1);

    /* var dropGroups = [];
    var grp = []; */
    var str = "";
    for (i=>drop in frameDrops) {
        var finalStr = drop;
        if (drop == frames[selectedFrame].frame) finalStr = "^" + finalStr + "^";
        if (i % 5 == 0 && str != "") str += "\n";
        str = [str, finalStr].join(", ");
    }
    
    str = [for (i in str.split("\n")) i.substr(2)].join("\n");
    
    sideTxt.text = "Frame Drops:\n" + str;
    sideTxt.updateHitbox();
    sideTxt.screenCenter();
    sideTxt.x = 10;

    sideTxt.applyMarkup(sideTxt.text, [ new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.CYAN), "^") ]);

    FlxTween.cancelTweensOf(camera.scroll);
    FlxTween.tween(camera.scroll, { x: frameObjs.members[selectedFrame].x - (FlxG.width/2) + (frameObjs.members[selectedFrame].width/2) }, 0.2, { ease: FlxEase.quadOut });

    if (!playedThisFrame) {
        playedThisFrame = true;
        FlxG.sound.play(Paths.sound("menu/volume"));
    }
}

function getIndexByFrame(frame) {
    for (i=>frameObj in frameObjs.members) {
        if (frames[i].frame == frame) return i;
    }
}