/*
-accidental-effect-1.scd-

Setup: Use thisProcess.interpreter().compileFile(path).value() to load the function into
a variable.

Description: Accidental effect created when experementing with Karplus-Strong synthesis.
The function accepts a buffer from the user and returns a new effected buffer within an
event variable. This module can be used to create a bitcrush like effect when arguments
are adjusted accordingly.

Arguments:
-- sourceBuf: Buffer provided by the user. The function manipulates this buffer and returns the result.
-- numChannels: Number of channels of the signal provided.
-- segmentLength: Since the algorithm is faulty, not sure what exactly this does... Experement to create unpredictable sounds!
-- numIterations: Number of times to repeat the algorithm.
-- frameMul: Value by which to scale the amplitude of manipulated frames within the algorithm.

Return: This function executes asynchronously. Beacuse of this, an event is returned, and not the resulting
buffer itself. When the function is finished, the event's condition (stored at event key cond) is signaled
and the buffer will be accessable at the event key retVal.
*/
(
{
	arg sourceBuf, numChannels, segmentLength = 500, numIterations = 10, frameMul = 0.5;
	var loopIteration = 0, previousL = 0, previousR = 0, bufArray, maxFrame, retVar = ();

	Routine.new({

		sourceBuf.postln;
		numChannels.postln;
		// Load the buffer into an array of floats and wait for completion.
		sourceBuf.loadToFloatArray(action: { arg output; bufArray = output; });
		s.sync();

		// Reverse the contents of the array. This makes visualization of the process easier.
		bufArray = bufArray.reverse();

		// Faulty algorithm made when experementing with Karplus-Strong synthesis...
		numIterations.do({

			bufArray = bufArray.collect({

				arg frame, index;

				if((index % (segmentLength * numChannels)) == loopIteration,
					{ previousL = (previousL * frameMul) + frame; },
					{ previousR = (previousR * frameMul) + frame; }
				);
			});

			loopIteration = loopIteration + 1;
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
			"accidental-effect-1.scd - Buffer stored at event key retVal.".postln();
		});
		s.sync();
	}).play();

	// Condition which will be signaled when the buffer is generated.
	retVar[\cond] = Condition.new();
	retVar;
};
)