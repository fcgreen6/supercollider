(
{
	arg sourceBuf, numChannels, segmentLength = 500, numIterations = 10, frameMul = 0.5;
	var iteration = 0, previousL = 0, previousR = 0, bufArray, maxFrame, retVar = ();

	Routine.new({

		sourceBuf.postln;
		numChannels.postln;
		// Load the buffer into an array of floats and wait for completion.
		sourceBuf.loadToFloatArray(action: { arg output; bufArray = output; });
		s.sync();

		// Reverse the contents of the array. This makes visualization of the process easier.
		bufArray = bufArray.reverse();

		numIterations.do({

			bufArray = bufArray.collect({

				arg frame, index;

				if((index % (segmentLength * numChannels)) == iteration,
					{ previousL = (previousL * frameMul) + frame; },
					{ previousR = (previousR * frameMul) + frame; }
				);
			});

			iteration = iteration + 1;
		});

		bufArray = bufArray.reverse();

		// Since segments have been repeatedly added together, the float array must be rescalled.
		maxFrame = bufArray[0];
		bufArray.do({

			// Find the largest frame in the array.
			arg curFrame;
			if(curFrame > maxFrame,

				{ maxFrame = curFrame; }
			);
		});

		// Scale the array according the the largest frame.
		bufArray = bufArray * (1 / maxFrame) * 0.2;

		// Convert float array to buffer and store result in return event.
		Buffer.loadCollection(s, bufArray, numChannels, { arg buf;

			retVar[\retVal] = buf;
			retVar[\cond].test = true;
			retVar[\cond].signal();
			"strong-synth-effect.scd - Buffer stored at event key retVal.".postln();
		});
		s.sync();
	}).play();

	// Condition which will be signaled when the buffer is generated.
	retVar[\cond] = Condition.new();
	retVar;
};
)