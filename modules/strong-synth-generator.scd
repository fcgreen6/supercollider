/*
-strong-synth-generator.scd-

Setup: Use thisProcess.interpreter().compileFile(path).value() to load the function into
a variable.

Description: Generates a buffer from a predefined array of floating point numbers. Array indices are divided
into segments of a specified length. The function adds each segment to the value of the following segment.
This process is repeated a specified number of iterations. The resulting array is scaled and converted into
a buffer.

Arguments:
-- oscType: Tupe of oscillator to initialize the float array to.
-- numChannels: Number of channels of the signal provided.
-- numSeconds: The number of seconds to make the final buffer.
-- segmentLength: The length of each segment of frames.
-- numIterations: Number of times to repeat the proccess of adding segments together.
-- frameMul: Value by which to scale the amplitude of added segments.

Return: This function executes asynchronously. Beacuse of this, an event is returned, and not the resulting
buffer itself. When the function is finished, the event's condition (stored at event key cond) is signaled
and the buffer will be accessable at the event key retVal.
*/
(
{
	arg oscType, numChannels, numSeconds, segmentLength = 500, numIterations = 10, frameMul = 0.5;
	var bufArray, maxFrame, retVar = ();

	Routine.new({

		// Sine oscillator locked at A 440.
		if(oscType == \sine,

			{ var numFrames = s.sampleRate() * numSeconds;
				bufArray = Array.fill(numFrames, { arg index; ((1 / numFrames) * index * 880pi).sin().abs() } ); }
		);

		// Pink noise like oscillator.
		if(oscType == \pink,
			{ bufArray = Array.exprand(s.sampleRate() * numSeconds, 0.00001, 1.0); }
		);

		// White noise oscillator is created by default.
		if(bufArray == nil,
			{ bufArray = Array.rand(s.sampleRate() * numSeconds, 0.0, 1.0); }
		);

		// Buffer is laced with itself up to the number of channels.
		bufArray = Array.fill(numChannels, { bufArray }).lace;

		// Reverse the contents of the array. This makes visualization of the process easier.
		bufArray = bufArray.reverse();

		// Do the process for the specified number of iterations.
		numIterations.do({

			for(0, bufArray.size() - 1, {

				// The first segment is not effected since there is no segment preceding it.
				// This if statement begins adding segments after the first segment.
				arg iteration;
				if(iteration >= (segmentLength * numChannels),

					{ bufArray.put(iteration, bufArray[iteration] + (bufArray[iteration - (segmentLength * numChannels)] * frameMul)); }
				);
			});
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
			"strong-synth-generator.scd - Buffer stored at event key retVal.".postln();
		});
		s.sync();
	}).play();

	// Condition which will be signaled when the buffer is generated.
	retVar[\cond] = Condition.new();
	retVar;
};
)