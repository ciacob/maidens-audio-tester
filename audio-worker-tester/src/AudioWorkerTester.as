package {

import eu.claudius.iacob.synth.events.SystemStatusEvent;
import eu.claudius.iacob.synth.sound.generation.SynthProxy;
import eu.claudius.iacob.synth.utils.AudioParallelRenderer;
import eu.claudius.iacob.synth.utils.AudioUtils;
import eu.claudius.iacob.synth.utils.ProgressReport;
import eu.claudius.iacob.synth.utils.SoundLoader;

import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.ByteArray;

import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

/**
 * Tester for the AudioParallelRenderer class.
 */
public class AudioWorkerTester extends Sprite {

    // Testing-related variables/constants.
    [Embed(source="../../audio-worker/bin/audio-worker.swf", mimeType="application/octet-stream")]
    private static const AUDIO_WORKER_BYTES:Class;
    private static const SOUNDS_HOME:String = 'sounds';

    private var _audioStorage:ByteArray;
    private var _soundLoader:SoundLoader;
    private var _loadedSounds:Object;
    private var _parallelRenderer:AudioParallelRenderer;

    // UI-related variables/constants
    private static const WAVEFORM_HEIGHT:int = 100;
    private static const MARGIN:uint = 10;
    private var _stageBackground:Shape;
    private var _innerRectangle:Rectangle;
    private var _buttons:Array;
    private var _waveFormContainer:Sprite;

    public function AudioWorkerTester() {
        // UI-related initialization
        _buttons = [];
        _stageBackground = new Shape;
        _waveFormContainer = new Sprite;
        addEventListener(Event.ADDED_TO_STAGE, _onStageReady);

        // Testing-related initialization
        _soundLoader = new SoundLoader;
        _soundLoader.addEventListener(SystemStatusEvent.REPORT_EVENT, _onReportReceived);
    }

    /**
     * Executed when the "Load sounds" button was clicked.
     * @param event
     */
    private function _onLoadSoundsRequested(event:MouseEvent):void {
        trace('Preloading sounds...');
        _soundLoader.preloadSounds(Utils.makeSoundPresets(), SOUNDS_HOME);
    }

    /**
     * Executed when the 'Initialize Audio Parallel Renderer' button was clicked.
     * @param event
     */
    private function _onAudioParallelRendererInitRequested(event:MouseEvent):void {
        trace('Initializing the audio parallel renderer...');
        var workerSrc:ByteArray = (new AUDIO_WORKER_BYTES) as ByteArray;
        _parallelRenderer = new AudioParallelRenderer(workerSrc, _onParallelRendererSuccess, _onParallelRendererError);
        trace('_parallelRenderer.canOperate:', _parallelRenderer.canOperate);
    }

    /**
     * Executed when the 'Assign rendering work' button was clicked.
     * @param event
     */
    private function _onAssignRenderingWorkRequested(event:MouseEvent):void {
        trace('Assigning work to the renderer...');
        var sessionId:String = Strings.UUID;
        if (!_audioStorage) {
            _audioStorage = AudioUtils.makeSamplesStorage();
        } else {
            _audioStorage.clear();
        }
        var testTracks:Array = Utils.produceTestTracks();
        _parallelRenderer.assignWork(testTracks, _audioStorage, sessionId, _loadedSounds);
    }

    /**
     * Executed when the audio parallel renderer successfully finished rendering given (MIDI) tracks into audio.
     * @param renderer
     */
    private function _onParallelRendererSuccess(renderer:AudioParallelRenderer):void {
        trace('SUCCESS reported from the audio parallel renderer.');

        // Draw a waveform of the rendered audio.
        var $drawWaveForm : Function = eu.claudius.iacob.synth.utils.Graphics.drawWaveForm;
        trace ('~~~~~~ _audioStorage.length:', _audioStorage.length);
        $drawWaveForm (_audioStorage, _waveFormContainer);

        var proxy : SynthProxy = new SynthProxy(_audioStorage);
        _audioStorage.position = 0;
        proxy.invalidateAudioCache();
        proxy.playBackPrerenderedAudio();
    }

    /**
     * Executed when the audio parallel renderer encountered an error while rendering given (MIDI) tracks into audio.
     * @param renderer
     */
    private function _onParallelRendererError(renderer:AudioParallelRenderer):void {
        trace('ERROR reported from the audio parallel renderer. Details:', _dumpObject(renderer.errorDetail));
    }

    /**
     * Executed when the global `_soundLoader` (a SoundLoader instance) sends a progress report by means of a
     * SystemStatusEvent.
     * @param event
     */
    private function _onReportReceived(event:SystemStatusEvent):void {
        var report:ProgressReport = event.report;
        trace(report);
        if (report.state == ProgressReport.STATE_READY_TO_RENDER) {
            _loadedSounds = _soundLoader.sounds;
        }
    }

    /**
     * Helper method to produce a read-out of all the properties of a given Object.
     * @param object
     */
    private function _dumpObject(object:Object):String {
        var out:Array = [];
        var key:String;
        var value:String;
        for (key in object) {
            value = ('' + object[key]);
            out.push(key + CommonStrings.COLON_SPACE + value);
        }
        return (CommonStrings.NEW_LINE + CommonStrings.TAB + out.join(CommonStrings.NEW_LINE + CommonStrings.TAB));
    }


    //==================================================================================================================
    // Build the UI. Since this is a pure ActionScript application, its UI must be built from scratch.
    // =================================================================================================================

    /**
     *
     * @param event
     */
    private function _onStageReady(event:Event):void {

        // Prepare stage
        removeEventListener(Event.ADDED_TO_STAGE, _onStageReady);
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.quality = StageQuality.BEST;
        stage.addEventListener(Event.RESIZE, _onStageResized);
        stage.addChild(_stageBackground);

        // Define buttons
        _buttons.push(
                _makeButton("Load sounds", _onLoadSoundsRequested),
                _makeButton('Initialize Audio Parallel Renderer', _onAudioParallelRendererInitRequested),
                _makeButton('Assign rendering work', _onAssignRenderingWorkRequested)
        );

        // Define Waveform area
        stage.addChild(_waveFormContainer);
    }

    /**
     *
     * @param event
     */
    private function _onStageResized(event:Event):void {
        _innerRectangle = new Rectangle(MARGIN, MARGIN, (stage.stageWidth - MARGIN * 2),
                (stage.stageHeight - WAVEFORM_HEIGHT - MARGIN * 3));
        _drawStageBackground();
        _drawWaveFormAreaBackground();
        _arrangeButtons(_buttons);
        _arrangeWaveformArea();
    }

    /**
     *
     */
    private function _drawStageBackground():void {
        var g:Graphics = _stageBackground.graphics;
        g.clear();
        g.lineStyle(1, 0xcccccc);
        g.beginFill(0xf1f1f1);
        g.drawRect(1, 1, stage.stageWidth - 2, stage.stageHeight - 2);
        g.endFill();
    }

    /**
     *
     */
    private function _drawWaveFormAreaBackground():void {
        var g:Graphics = _waveFormContainer.graphics;
        g.clear();
        g.lineStyle(1, 0xcccccc);
        g.beginFill(0xffffff);
        g.drawRect(0, 0, _innerRectangle.width, WAVEFORM_HEIGHT);
        g.endFill();
    }

    /**
     *
     * @param $buttons
     */
    private function _arrangeButtons($buttons:Array):void {
        var buttons:Array = $buttons.concat();
        var rows:Array = [];
        var row:Array;

        // "Rows" are content-aware entities, that keep track of both their object's total width and above rows' total
        // height.
        var makeRow:Function = function ():Array {
            var row:Array = [];
            row.width = 0;
            row.height = 0;
            row.y = 0;
            var rowIndex:int;
            var numPrevRows:int = rows.length;
            var prevRow:Object;
            for (rowIndex = 0; rowIndex < numPrevRows; rowIndex++) {
                prevRow = rows[rowIndex];
                var topMargin:int = ((rows.length != 0) ? MARGIN : 0);
                row.y += (prevRow.height + topMargin);
            }

            // Decide whether "this" row has enough room for given button. The first button will always be accepted,
            // regardless of its size.
            row.canHoldButton = function (button:Sprite):Boolean {
                if (row.length == 0) {
                    return true;
                }
                return ((row.width + button.width + MARGIN * 2) <= _innerRectangle.width);
            }

            // Takes charge of given button, correctly placing it on the canvas in the process.
            row.acceptButton = function (button:Sprite):void {
                var leftMargin:int = ((row.length != 0) ? MARGIN : 0);
                button.x = _innerRectangle.x + (row.width + leftMargin);
                button.y = _innerRectangle.y + row.y;
                row.width += (button.width + leftMargin);
                if (button.height > row.height) {
                    row.height = button.height;
                }

                row.push(button);
            }
            return row;
        };

        // Loop over all provided buttons and distribute them on rows, based on their individual width.
        var button:Sprite;
        while (buttons.length > 0) {
            button = buttons.shift();
            if (!row) {
                row = makeRow();
            }
            if (row.canHoldButton(button)) {
                row.acceptButton(button);
            } else {
                rows.push(row);
                row = null;
                buttons.unshift(button);
            }
        }
    }

    /**
     *
     */
    private function _arrangeWaveformArea():void {
        _waveFormContainer.x = MARGIN;
        _waveFormContainer.y = (_innerRectangle.bottom + MARGIN);
    }

    /**
     *
     * @param $label
     * @param handler
     * @param color
     * @param textColor
     * @param $stage
     * @return
     */
    private function _makeButton($label:String,
                                 handler:Function = null,
                                 color:uint = 0xcccccc,
                                 textColor:uint = 0x444444,
                                 $stage:Stage = null):Sprite {
        if (!$stage) {
            $stage = this.stage;
        }
        if (!$stage) {
            return null;
        }
        var container:Sprite = new Sprite;
        container.mouseChildren = false;
        container.useHandCursor = true;
        container.buttonMode = true;
        var background:Shape = new Shape;
        var textField:TextField = new TextField;
        textField.defaultTextFormat = new TextFormat('Consolas', 16, textColor);
        textField.text = $label;
        textField.autoSize = TextFieldAutoSize.RIGHT;
        textField.selectable = false;
        textField.background = true;
        textField.backgroundColor = color;
        textField.x = 16;
        textField.y = 6;
        var g:Graphics = background.graphics;
        g.lineStyle(1, textColor, 0.75, true);
        g.beginFill(color);
        g.drawRoundRect(0, 0, textField.width + 32, textField.height + 12, 6, 6);
        g.endFill();
        container.addChild(background);
        container.addChild(textField);
        $stage.addChild(container);
        if (handler) {
            var onRemoved:Function = function (event:Event):void {
                container.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
                container.removeEventListener(MouseEvent.CLICK, onClick);
            }
            var onClick:Function = function (event:MouseEvent):void {
                handler(event);
            }
            container.addEventListener(MouseEvent.CLICK, onClick);
            container.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        }
        return container;
    }

}
}
