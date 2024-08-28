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
	~synthLoop = Buffer.read(s, ~samplePath ++ "synthloop.wav");

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
	~synthLoopVariations[\value] = Array.new(4);

	// Create some variations on the synth loop and store them in ~synthLoopVariations as an array.
	~applyModules.value(~synthLoop, 2, 1000, 10, 0.5, nil, ~strongSynthFx, ~synthLoopVariations)[\cond].wait();
	~applyModules.value(~synthLoop, 2, 2000, 5, 0.7, nil, ~strongSynthFx, ~synthLoopVariations)[\cond].wait();
	~applyModules.value(~synthLoop, 2, 4000, 10, 0.5, nil, ~strongSynthFx, ~synthLoopVariations)[\cond].wait();
	~applyModules.value(~synthLoop, 2, 400, 12, 0.8, nil, ~strongSynthRev, ~synthLoopVariations)[\cond].wait();
	~synthLoopVariations = ~synthLoopVariations[\value];

	// Create new groups afer ctrl period is pressed...
	ServerTree.add({

		~mainGroup = Group.new();
		~fxGroup = Group.new(~mainGroup, \addAfter);
	});
	ServerTree.run();
});
)

// Test Code...
// Created a function compatable with the function player which plays the synth loop
// a specified number of times. On the last repetion, the user can choose one of four
// fills.
(
SynthDef(\synthLoopPlay, {

	arg gate = 1;
	var signal;

	signal = PlayBuf.ar(2, ~synthLoop, 1.0, doneAction: 2);

	signal = signal * EnvGen.ar(
		Env.new(
			[1, 0, 1],
			[~synthLoop.duration() - ~beat, ~beat / 2],
			[6, -6],
			0
		),
		gate,
		doneAction: 2
	);

	signal = signal * EnvGen.ar(
		Env.new(
			[0, 1, 1, 0],
			[0.05, ~synthLoop.duration() - 0.10, 0.05]
		)
	);

	Out.ar(0, signal);
}).add();

SynthDef(\loopVariationPlay, {

	arg gate1 = 1, gate2 = 1, gate3 = 1, gate4 = 1;
	var signal1, signal2, signal3, signal4;

	signal1 = PlayBuf.ar(2, ~synthLoopVariations[0], 1.0, doneAction: 2);
	signal2 = PlayBuf.ar(2, ~synthLoopVariations[1], 1.0, doneAction: 2);
	signal3 = PlayBuf.ar(2, ~synthLoopVariations[2], 1.0, doneAction: 2);
	signal4 = PlayBuf.ar(2, ~synthLoopVariations[3], 1.0, doneAction: 2);

	signal1 = signal1 * EnvGen.ar(
		Env.new(
			[0, 1, 0],
			[~synthLoop.duration() - ~beat, ~beat / 2],
			[6, -6],
			0
		),
		gate1,
		doneAction: 2
	);

	signal2 = signal2 * EnvGen.ar(
		Env.new(
			[0, 1, 0],
			[~synthLoop.duration() - ~beat, ~beat / 2],
			[6, -6],
			0
		),
		gate2,
		doneAction: 2
	);

	signal3 = signal3 * EnvGen.ar(
		Env.new(
			[0, 1, 0],
			[~synthLoop.duration() - ~beat, ~beat / 2],
			[6, -6],
			0
		),
		gate3,
		doneAction: 2
	);

	signal4 = signal4 * EnvGen.ar(
		Env.new(
			[0, 1, 0],
			[~synthLoop.duration() - ~beat, ~beat / 2],
			[6, -6],
			0
		),
		gate4,
		doneAction: 2
	);

	signal1 = signal1 + signal2 + signal3 + signal4;

	signal1 = signal1 * EnvGen.ar(
		Env.new(
			[1, 1, 0],
			[~synthLoop.duration() - 0.05, 0.05]
		)
	);

	Out.ar(0, signal1);
}).add();

~a1 = {

	arg repetitions = 1, fill = false, fillVariation = 1;

	Routine({

		repetitions.do({

			arg iteration;

			if((iteration == (repetitions - 1)) && fill,
				{
					var synth1, synth2;

					synth1 = Synth.new(\synthLoopPlay, target: ~mainGroup);
					synth2 = Synth.new(\loopVariationPlay, target: ~mainGroup);

					(~beat / 2).wait();

					synth1.set(\gate, 0);
					synth2.set(\gate ++ fillVariation.asString(), 0);
				},
				{
					Synth.new(\synthLoopPlay, target: ~mainGroup);
					(~beat * 8).wait();
				}
			);
		});
	}).play();
};

~seq = [{ ~a1.value(1, true) }, \, \, \, \, \, \, \];
~seq = ~seq ++ [{ ~a1.value(1, true, 2) }, \, \, \, \, \, \, \];
~seq = ~seq ++ [{ ~a1.value(1, true, 3) }, \, \, \, \, \, \, \];
~seq = ~seq ++ [{ ~a1.value(1, true, 4) }, \, \, \, \, \, \, \];
~player.value(~seq, ~beat, true);
)