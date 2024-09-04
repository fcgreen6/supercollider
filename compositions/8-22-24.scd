(
// Remove callback functions which will be created in this program from the server.
ServerTree.removeAll();
ServerQuit.removeAll();
ServerQuit.add({ ServerTree.removeAll(); ServerQuit.removeAll(); });

// Clear the node tree.
CmdPeriod.run();

// Global variables for track tempo.
~bpm = 105;
~beat = 60/~bpm;

~scPath = PathName(thisProcess.nowExecutingPath()).parentPath(); // Compositions folder...
~scPath = PathName(~scPath).parentPath(); // SuperColider development folder...

~modulePath = ~scPath ++ "modules/"; // Modules folder...
~samplePath = ~scPath ++ "samples/8-22-24/"; // Samples folder...

// Load modules...
~strongSynthGen = thisProcess.interpreter().compileFile(~modulePath ++ "strong/strong-synth-generator.scd").value();
~strongSynthFx = thisProcess.interpreter().compileFile(~modulePath ++ "strong/strong-synth-effect.scd").value();
~strongSynthRev = thisProcess.interpreter().compileFile(~modulePath ++ "strong/variations/strong-reverse-iterations.scd").value();
~strongSynthAccidental = thisProcess.interpreter().compileFile(~modulePath ++ "accidental/accidental-effect-1.scd").value();
~player = thisProcess.interpreter().compileFile(~modulePath ++ "sequencing/function-sequence-player.scd").value();

// Create busses here...
s.newBusAllocators();
~mainSynthBus = Bus.audio(s, 2);

s.waitForBoot({

	// Load bass samples into an array...
	~bassSamples = Array.new(3);
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass1.wav"));
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass2.wav"));
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass3.wav"));

	// Load piano samples into an array...
	~pianoSamples = Array.new(4);
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano1.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano2.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano3.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano4.wav"));

	// Load synth samples into an array...
	~synthSamples = Array.new(4);
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth1.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth2.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth3.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth4.wav"));

	// Load synth loop...
	~synthLoops = Array(2);
	~synthLoops = ~synthLoops.add(Buffer.read(s, ~samplePath ++ "synthloop.wav"));
	~synthLoops = ~synthLoops.add(Buffer.read(s, ~samplePath ++ "synthloop2.wav"));

	// Wait for buffer creation...
	s.sync();

	// Helper function compatable with strong synth modules.
	~applyModules = {

		// "arg" arguments are the arguments to be supplied to the module.
		// Module is the module to be applied. outEvent is the event where the processed buffer is stored.
		arg arg1, arg2, arg3, arg4, arg5, arg6, module, outEvent;
		var retVar = ();

		Routine.new({

			var moduleVal;

			// Execute the module's function and wait for the result.
			moduleVal = module.value(arg1, arg2, arg3, arg4, arg5, arg6);
			moduleVal[\cond].wait();
			outEvent[\value] = outEvent[\value].add(moduleVal[\retVal]);

			// Signal that the function has finished executing.
			retVar[\cond].test = true;
			retVar[\cond].signal();
		}).play();

		retVar[\cond] = Condition.new();
		retVar;
	};

	// Event for colecting variations on the synth loop.
	~synthLoopVariations = ();
	~synthLoopVariations[\value] = Array.new(2);

	// Create some variations on the synth loop and store them in ~synthLoopVariations as an array.
	~applyModules.value(~synthLoops[0], 2, 500, 6, 0.87, nil, ~strongSynthRev, ~synthLoopVariations)[\cond].wait();
	~applyModules.value(~synthLoops[1], 2, 13000, 100, 0.07, nil, ~strongSynthFx, ~synthLoopVariations)[\cond].wait();
	~synthLoopVariations = ~synthLoopVariations[\value];

	// Event for collecting layers of the main bass.
	~mainBassLayers = ();
	~mainBassLayers[\value] = Array.new(3);

	// Generate a synth to use for a bass layer.
	~strongBassStarter = ~strongSynthGen.value(\pink, 2, 1.0, s.sampleRate() / 110, 100, 0.5);
	~strongBassStarter[\cond].wait();
	~strongBassStarter = ~strongBassStarter[\retVal];

	// Create some layers for the bass and store them in ~mainBassLayers. ~strongBassStarter is freed after use.
	~applyModules.value(~pianoSamples[3], 2, s.sampleRate() / 55, 100, 0.25, nil, ~strongSynthRev, ~mainBassLayers)[\cond].wait();
	~applyModules.value(~bassSamples[0], 2, s.sampleRate() / 110, 100, 0.5, nil, ~strongSynthRev, ~mainBassLayers)[\cond].wait();
	~applyModules.value(~strongBassStarter, 2, s.sampleRate() / 110 + 1, 101, 0.5, nil, ~strongSynthRev, ~mainBassLayers)[\cond].wait();
	~mainBassLayers = ~mainBassLayers[\value];
	~strongBassStarter.free();

	~bassFills = ();
	~bassfills[\value] = Array.new(10);

	~applyModules.value(~bassSamples[2], 2, s.sampleRate() / 84, 5, 0.4, nil, ~strongSynthRev, ~bassFills)[\cond].wait();

	SynthDef(\mainSynthBus, {

		var signal;
		signal = In.ar(~mainSynthBus, 2);

		Out.ar(0, signal);
	}).add();

	s.sync();

	// Create new groups afer ctrl period is pressed...
	ServerTree.add({

		~mainGroup = Group.new();
		~fxGroup = Group.new(~mainGroup, \addAfter);

		Synth(\mainSynthBus, target: ~fxGroup);
	});
	ServerTree.run();
});
)

// Test Code...
(
SynthDef(\synthLoop, {

	arg gate = 1;
	var signal;

	signal = PlayBuf.ar(2, ~synthLoops[1], 1.0, doneAction: 2) * 4.dbamp();

	signal = signal * EnvGen.ar(
		Env.new(
			[1, 1, 0],
			[~beat / 2, ~synthLoops[1].duration() - ~beat],
			[0, 3.5],
			1
		),
		gate,
		doneAction: 2
	);

	Out.ar(~mainSynthBus, signal);
}).add();

SynthDef(\loopVariation1, {

	var signal;

	signal = PlayBuf.ar(2, ~synthLoopVariations[0], doneAction: 2) * (-2.dbamp());

	signal = signal * EnvGen.ar(
		Env.new(
			[0, 0,  1],
			[~beat * 4, ~synthLoopVariations[0].duration() - (~beat * 4)],
			[0, 4.5],
		)
	);

	Out.ar(~mainSynthBus, signal);
}).add();

SynthDef(\loopVariation2, {

	var signal;

	signal = PlayBuf.ar(2, ~synthLoopVariations[1], doneAction: 2) * (30.dbamp());

	signal = signal * EnvGen.ar(
		Env.new(
			[0, 0,  1],
			[~beat * 4, ~synthLoopVariations[1].duration() - (~beat * 4)],
			[0, 10],
		)
	);

	signal = Balance2.ar(signal[0], signal[1], SinOsc.ar(s.sampleRate() / 13000).bipolar(0.4));

	Out.ar(~mainSynthBus, signal);
}).add();

SynthDef(\bassLayer1, {

	var signal1, signal2;

	signal1 = PlayBuf.ar(2, ~mainBassLayers[0], 0.5);
	signal2 = PlayBuf.ar(2, ~mainBassLayers[1], 0.5);

	signal1 = signal1 * EnvGen.ar(
		Env.new(
			[0, 0, 0.5],
			[~beat / 2, ~beat],
			[0, -2]
		)
	);

	signal2 = signal2 * EnvGen.ar(
		Env.new(
			[1, 1, 0.7],
			[(~beat / 2), ~beat],
			[0, -2]
		)
	);

	signal1 = signal1 + signal2;
	signal1 = signal1 * (-10.dbamp());

	signal1 = signal1 * EnvGen.ar(
		Env.new(
			[1, 1, 0],
			[~beat + (~beat / 2), 0.2],
			[1]
		),
		doneAction: 2
	);

	Out.ar(0, signal1);
}).add();

SynthDef(\bassLayer2, {

	var signal;
	signal = PlayBuf.ar(2, ~mainBassLayers[2]);

	signal = signal * EnvGen.ar(
		Env.new(
			[0.05, 1],
			[0.3],
			[0]
		)
	);

	signal = signal * (-5.dbamp());
	signal = signal * EnvGen.ar(
		Env.new(
			[1, 1, 0],
			[~beat + (~beat / 2), 0.2],
			[1]
		),
		doneAction: 2
	);

	Out.ar(0, signal);
}).add();

~bassFills.do({

	arg buffer, index;

	SynthDef(\bassFill ++ (index + 1).asString(), {

		arg attack = 0, release = 0, gate = 1, startPos = 0, rate = 1;
		var signal;

		signal = PlayBuf.ar(2, ~bassFills[index], rate, startPos: s.sampleRate() * startPos, doneAction: 2);

		signal = signal * EnvGen.ar(
			Env.new(
				[0, 1, 0],
				[attack, release],
				[0, 0],
				1
			),
			gate,
			doneAction: 2
		);

		Out.ar(0, signal);
	}).add();
});

~p1 = {

	arg repetitions = 1, fill = false, fillVariation = 1;

	Routine({

		repetitions.do({

			arg iteration;

			if((iteration == (repetitions - 1)) && fill,
				{
					var synth1, synth2;

					synth1 = Synth.new(\synthLoop, target: ~mainGroup);
					synth2 = Synth.new(\loopVariation ++ fillVariation.asString(), target: ~mainGroup);

					(~beat / 2).wait();

					synth1.set(\gate, 0);
				},
				{
					Synth.new(\synthLoop, target: ~mainGroup);
					(~beat * 8).wait();
				}
			);
		});
	}).play();
};

~p2 = {

	Routine({

		var synth;

		Synth(\bassLayer2, target: ~mainGroup);
		Synth(\bassLayer1, target: ~mainGroup);

		(~beat * 3).wait();

		synth = Synth(\bassFill3, [\startPos, 0.6, \attack, 0.2, \release, 0.1], target: ~mainGroup);

		(~beat).wait();

		synth.set(\gate, 0);
	}).play();
};

~seq = [{ ~p1.value(1, true, 1) }, \, \, \, \, \, \, \];
~seq2 = [{ ~p2.value(); }, \, \, \];
~player.value(~seq, ~beat, true);
~player.value(~seq2, ~beat, true);
)

