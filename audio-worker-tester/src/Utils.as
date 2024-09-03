package {
import eu.claudius.iacob.synth.sound.map.NoteAttackInfo;
import eu.claudius.iacob.synth.sound.map.NoteTrackObject;
import eu.claudius.iacob.synth.sound.map.Timeline;
import eu.claudius.iacob.synth.sound.map.Track;
import eu.claudius.iacob.synth.utils.PresetDescriptor;

public class Utils {
    private static var _timeLine:Timeline;
    private static var _testTracks:Array;
    private static var _presets:Vector.<PresetDescriptor>;

    public function Utils() {
    }

    /**
     * Builds and compiles some (MIDI) tracks to provide the renderer some test material to work on.
     * @return
     */
    public static function produceTestTracks():Array {
        if (!_testTracks) {
            _timeLine = new Timeline;
            var piano0:Track = new Track('Piano', 0);
            var c_i7:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(72, 0.6, 0, 0, 1, false, false)]);
            var c_i8:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(72, 0.3, 0, 0, 1, false, false)]);
            var g2:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(79, 1)]);
            piano0.addObject(c_i7, 100, 600);
            piano0.addObject(c_i8, 750, 220);
            piano0.addObject(g2, 1000, 3000);

            var flute:Track = new Track('Flute', 73);
            var Cmajor:NoteTrackObject = new NoteTrackObject(
                    new <NoteAttackInfo>[
                        new NoteAttackInfo(60),
                        new NoteAttackInfo(64, 2, 50),
                        new NoteAttackInfo(67, 1, 100)
                    ]
            );
            var Ddim:NoteTrackObject = new NoteTrackObject(
                    new <NoteAttackInfo>[
                        new NoteAttackInfo(60),
                        new NoteAttackInfo(62, 2, 50),
                        new NoteAttackInfo(65, 1, 100),
                        new NoteAttackInfo(68, 1.5, 150)
                    ]
            );
            flute.addObject(Cmajor, 1000, 1000);
            flute.addObject(Ddim, 3000, 1000);

            var piano:Track = new Track('Piano', 0);
            var c_i1:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.3)]);
            var c_i2:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.2)]);
            var c_i3:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.7)]);
            var c_i4:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.4)]);
            var c_i5:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.2)]);
            var c_i6:NoteTrackObject = new NoteTrackObject(new <NoteAttackInfo>[new NoteAttackInfo(48, 0.6)]);
            piano.addObject(c_i1, 1333, 333);
            piano.addObject(c_i2, 1666, 333);
            piano.addObject(c_i3, 2000, 333);
            piano.addObject(c_i4, 2333, 333);
            piano.addObject(c_i5, 2666, 333);
            piano.addObject(c_i6, 3000, 2000);

            _timeLine.empty();
            _timeLine.addTrack(piano0);
            _timeLine.addTrack(flute);
            _timeLine.addTrack(piano);
            _testTracks = _timeLine.readOn();
        }
        return _testTracks;
    }

    /**
     * Compiles a list of sound presets to be used for testing.
     * @return
     */
    public static function makeSoundPresets():Vector.<PresetDescriptor> {
        if (!_presets) {
            _presets = new <PresetDescriptor>[
                new PresetDescriptor(0, 'Piano'),
                new PresetDescriptor(40, 'Violin'),
                new PresetDescriptor(73, 'Flute')
            ];
        }
        return _presets;
    }
}
}
