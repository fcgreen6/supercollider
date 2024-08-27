(
// Remove callback functions which will be created in this program from the server.
ServerTree.removeAll();
ServerQuit.removeAll();
ServerQuit.add({ ServerTree.removeAll(); ServerQuit.removeAll(); });

// Clear the node tree.
CmdPeriod.run();

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
// Create busses...

s.waitForBoot({

	~bassSamples = Array.new(3);
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass1.wav"));
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass2.wav"));
	~bassSamples = ~bassSamples.add(Buffer.read(s, ~samplePath ++ "bass3.wav"));

	~pianoSamples = Array.new(4);
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano1.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano2.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano3.wav"));
	~pianoSamples = ~pianoSamples.add(Buffer.read(s, ~samplePath ++ "piano4.wav"));

	~synthSamples = Array.new(4);
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth1.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth2.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth3.wav"));
	~synthSamples = ~synthSamples.add(Buffer.read(s, ~samplePath ++ "synth4.wav"));

	~synthLoop = Buffer.read(s, ~samplePath ++ "synthloop.wav");

	s.sync();

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

	~sampleBlend1 = ();
	~sampleBlend1[\value] = Array.new(5);

	~applyModules.value(~synthSamples[0], 2, 50, 50, 0.5, nil, ~strongSynthFx, ~sampleBlend1)[\cond].wait();
	~applyModules.value(~synthSamples[0], 2, 100, 100, 0.5, nil, ~strongSynthRev, ~sampleBlend1)[\cond].wait();

	ServerTree.add({

		~mainGroup = Group.new();
		~fxGroup = Group.new(~mainGroup, \addAfter);
	});
	ServerTree.run();
});
)

(
var bpm, beat;
bpm = 105;
beat = 60/bpm;

~loop = {

	arg repetitions = 1;

	Routine({

		repetitions.do({

			~synthLoop.play();
			(beat * 8).wait();
		});
	}).play();
};

~sequence = [\, \, \, \, \, \, \, \];
~sequence[0] = { ~sampleBlend1[\value][0].play(); ~loop.value(1); };
~sequence[4] = [{ ~sampleBlend1[\value][0].play(); }, { ~sampleBlend1[\value][1].play() }];

~player.value(~sequence, beat, true);
)