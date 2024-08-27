/*
-function-sequence-generator.scd-

Setup: Use thisProcess.interpreter().compileFile(path).value() to load the function into
a variable.

Description: Executes functions stored within an array at a constant interval (specified by the beat argument).
When the player encounters a nested array, the beat is subdivided based on the size of the inner array and
functions are executed accordingly. When the player encounters anything besides a function or an array
nothing is played during that beat.

Arguments:
-- sequence: Array containing functions and sub arrays.
-- beat: Beat duration by which to execute functions.
-- loop: Specifies wheather the player should continue looping.
*/
(
{
	arg sequence, beat, loop;
	var playSubsequence, iterations;

	// Set the number of iterations based on loop argument.
	if(loop,
		{ iterations = inf; },
		{ iterations = 1; }
	);

	// Function that is called when a subsequence is encountered.
	playSubsequence = {

		// Determine how to subdivide the beat based on the size of the inner array.
		arg subSequence;
		var subSequenceBeat = beat / subSequence.size();

		Routine({

			// Execute the functions within the inner array in sequence.
			subSequence.do({

				arg event;

				if(event.isKindOf(Function),
					{ event.value() };
				);

				subSequenceBeat.wait();
			});
		}).play();
	};

	Routine({

		iterations.do({

			// Execute the functions within the array in sequence.
			sequence.do({

				arg event;

				if(event.isKindOf(Function),
					{ event.value() };
				);

				// If an array is encounter, the subsequence function is called.
				if(event.isKindOf(Array),
					{ playSubsequence.value(event) };
				);

				beat.wait();
			});
		});
	}).play();
}
)