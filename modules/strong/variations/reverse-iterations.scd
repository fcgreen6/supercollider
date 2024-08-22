/*
-strong-synth-effect.scd-

Setup: Use thisProcess.interpreter().compileFile(path).value() to load the function into
a variable.

Description: An effect inspired by the Karplus-Strong synthesis algorithm. Converts a buffer
into an array of floating point numbers representing each frame of the buffer. Frames are then divided
into segments of a specified length. The function adds each segment to the value of the following segment.
This process is repeated a specified number of iterations. The resulting array is scaled and converted back into
a buffer.

Arguments:
-- sourceBuf: Buffer provided by the user. The function manipulates this buffer and returns the result.
-- numChannels: Number of channels of the signal provided.
-- segmentLength: The length of each segment of frames.
-- numIterations: Number of times to repeat the proccess of adding segments together.
-- frameMul: Value by which to scale the amplitude of added segments.

Return: This function executes asynchronously. Beacuse of this, an event is returned, and not the resulting
buffer itself. When the function is finished, the event's condition (stored at event key cond) is signaled
and the buffer will be accessable at the event key retVal.
*/
(
{
	arg sourceBuf, numChannels, segmentLength = 500, numIterations = 10, frameMul = 0.5;
	var bufArray, maxFrame, retVar = ();

	Routine.new({

		sourceBuf.postln;
		numChannels.postln;
		// Load the buffer into an array of floats and wait for completion.
		sourceBuf.loadToFloatArray(action: { arg output; bufArray = output; });
		s.sync();

		// Do the process for the specified number of iterations.
		numIterations.do({

			bufArray = bufArray.reverse();

			for(0, bufArray.size() - 1, {

				// The first segment is not effected since there is no segment preceding it.
				// This if statement begins adding segments after the first segment.
				arg iteration;
				if(iteration >= (segmentLength * numChannels),

					{ bufArray.put(iteration, bufArray[iteration] + (bufArray[iteration - (segmentLength * numChannels)] * frameMul)); }
				);
			});
		});

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