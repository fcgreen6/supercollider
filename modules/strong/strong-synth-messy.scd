s.boot;

(
var path = PathName(PathName(thisProcess.nowExecutingPath()).parentPath).parentPath;
path = path ++ "samples/cymbol.wav";

b = Buffer.read(s, path);
b.loadToFloatArray(action: { arg output; x = output; });
)

x.postln;

(
var previous = 0, iteration = 0;

x = x.reverse();

10.do({
	for(0, x.size() - 1, {

		arg iteration;
		if(iteration >= 1000,
			{ x.put(iteration, x[iteration] + (x[iteration - 1000] * 0.5)); }
		);
	});
});

x = x.reverse();
"done".postln;
)

(
~max = x[0];
x.do({
	arg frame;
	if(frame > ~max,
		{ ~max = frame },
		{ /* Do Nothing */ }
	);
});
)

(
x = x * (1 / ~max);
x = x * 0.2;
)

(
c = Buffer.loadCollection(s, x, 2, {arg buf; "done".postln})
)

b.plot();

b.numFrames()

c.numFrames()

b.play();

~max

(
~func = {

	arg sourceBuf, retVar, numFrames = 1000, numIterations = 10;
	var bufArray, maxFrame;

	Routine.new({

		sourceBuf.loadToFloatArray(action: { arg output; bufArray = output; });
		s.sync();

		bufArray = bufArray.reverse();

		numIterations.do({

			for(0, bufArray.size() - 1, {

				arg iteration;
				if(iteration >= numFrames,

					{ bufArray.put(iteration, bufArray[iteration] + (bufArray[iteration - numFrames] * 0.5)); }
				);
			});
		});

		bufArray = bufArray.reverse();

		maxFrame = bufArray[0];
		bufArray.do({

			arg curFrame;
			if(curFrame > maxFrame,

				{ maxFrame = curFrame; }
			);
		});

		bufArray = bufArray * (1 / maxFrame) * 0.2;

		Buffer.loadCollection(s, bufArray, 2, { arg buf;
			retVar[\retVal] = buf;
			"strong-synth.scd - Buffer stored at event key retVal.".postln();
		});
	}).next();
};
)

~test = ();
~func.value(b, ~test, 500, 4);

~test[\retVal].play

t = Ref.new(~test);
t.set(1);
/*1000.do({

	x = x.collect({

		arg frame, index;

		if((index % 1000) == iteration,
			{ previousL = (previousL * 0.5) + frame; previousL },
			{ previousR = (previousR * 0.5) + frame; previousR }
		);
	});

	iteration = iteration + 1;
});*/