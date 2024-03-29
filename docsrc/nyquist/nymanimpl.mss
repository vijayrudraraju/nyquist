@part(Implementation,root "nyquistman2.mss")
@appendix(Extending Nyquist)
@label(extending-app)
@p(WARNING:)
Nyquist sound functions look almost like a human wrote them; they even have
a fair number of comments for human readers.  Don't be fooled: virtually all 
Nyquist functions are written by a special translator.  If you try to write
a new function by hand, you will probably not succeed, and even if you do,
you will waste a great deal of time.  (End of Warning.)


@section(Translating Descriptions to C Code)

The translator code used to extend Nyquist resides in the @code(trnsrc)
directory.  This directory also contains a special @code(init.lsp), so if
you start XLisp or Nyquist in this directory, it will automatically read
@code(init.lsp), which in turn will load the translator code (which resides
in several files).

Also in the @code(trnsrc) directory are a number of @code(.alg) files, which
contain the source code for the translator (more on these will follow), and
a number of corresponding @code(.h) and @code(.c) files.  

To translate a @code(.alg) file to @code(.c) and @code(.h) files, you start
XLisp or Nyquist in the @code(trnsrc) directory and type
@begin(example)
(translate "prod")
@end(example)
where @code("prod") should really be replaced by the filename (without a
suffix) you want to translate.  Be sure you have a saved, working copy of
Nyquist or Xlisp before you recompile!  

@p(Note:) On the Macintosh, just run Nyquist out of the @code(runtime) directory and then use the @code(Load) menu command to load @code(init.lsp) from the @code(trnsrc) directory.  This will load the translation code and change Nyquist's current directory to @code(trnsrc) so that commands like @code[(translate "prod")] will work.

@section(Rebuilding Nyquist)

After generating @code(prod.c) and 
@code(prod.h), you need to recompile Nyquist.  For Unix systems, you will
want to generate a new Makefile.  Modify @code(transfiles.lsp) in your main
Nyquist directory, run Xlisp or Nyquist and load @code(makefile.lsp).
Follow the instructions to set your machine type, etc., and 
execute @code[(makesrc)] and @code[(makefile)].

@begin(comment)
@subsection(Special Macintosh Instructions)

For the Code Warrior/Macintosh implementation, you will need to generate new Lisp-to-C interface files and then modify your project file.  To generate Lisp-to-C interface files, first modify the file @code(:nyqsrc:sndfn.cl) to include your newly generated @code(.h) file.  If you are not familiar with naming Macintosh folders, this file may look a bit odd.  The initial colon in a file name means to start in the current folder. After that, colons separate folder and file names.  For example,
@begin(example)
:tran:osc.h
@end(example)
means to start from the current directory, go to the @code(tran) directory, and there find the @code(osc.h) file.

After modifying @code(sndfn.cl), run the @code(intgen) program, which must be in the top-level Nyquist directory (the parent directory to @code(nyqsrc) and @code(tran). (If you build the @code(intgen) program in @code(misc), copy it to the parent directory.) After starting @code(intgen), to the command line, type:
@begin(example)
@@:nyqsrc:sndfn.cl
@end(example)
which tells @code(intgen) to use the contents of the @code(sndfn.cl) file as a command line. Read about @code(intgen) in Appendix @ref(intgen-app).

Next, add the @code(.c) file generated by @code(translate)  (e.g. @code(prod.c)) to your Nyquist project and recompile Nyquist. 
@end(comment)

@section(Accessing the New Function)

The new Lisp function will generally be named with a @code(snd-) prefix,
e.g. @code(snd-prod).  You can test this by running Nyquist.  Debugging is
usually a combination of calling the code from within the interpreter,
reading the generated code when things go wrong, and using a C debugger to
step through the inner loop of the generated code.  An approach I like is to
set the default sample rate to 10 hertz.  Then, a one-second sound has only
10 samples, which are easy to print and study on a text console.

For some functions,
you must write some Lisp code to impose
ordinary Nyquist behaviors such as stretching and time shifting.  A
good approach is to find some structurally similar functions and see how
they are implemented.  Most of the Lisp code for Nyquist is in
@code(nyquist.lsp).

Finally, do not forget to write up some documentation.  Also, contributions are
welcome.  Send your @code(.alg) file, documentation, Lisp support
functions for @code(nyquist.lsp), and examples or test programs
to @code(rbd@@cs.cmu.edu).  I will either put them in the next release or
make them available at a public ftp site.


@section(Why Translation?)
Many of the Nyquist signal processing operations are similar in form, but
they differ in details. This code is complicated by many factors: Nyquist
uses lazy evaluation, so the operator must check to see that input samples
are available before trying to access them. Nyquist signals can have
different sample rates, different block sizes, different block boundaries,
and different start times, all of which must be taken into account.  The
number of software tests is enormous. (This may sound like a lot of
overhead, but the overhead is amortized over many iterations of the inner
loop. Of course setting up the inner loop to run efficiently is one more
programming task.)

The main idea behind the translation is that all of the checks and setup
code are similar and relatively easy to generate automatically. Programmers
often use macros for this sort of task, but the C macro processor is too
limited for the complex translation required here. To tell the translator
how to generate code, you write @code(.alg) files, which provide many
details about the operation in a declarative style.  For example, the code
generator can make some optimizations if you declare that two input signals
are commutative (they can be exchanged with one another). The main part of
the @code(.alg) file is the inner loop which is the heart of the signal
processing code.

@section(Writing a .alg File)
@p(WARNING:) Translation relies heavily on string substitution, which
is fragile. In particular, variables with names that are substrings of
other variables will cause problems. For example if you declare STATE
variables "phase" and "iphase", then the translator will globally
substitute "phase_reg" for "phase", converting "phase" to "phase_reg"
and iphase" to "iphase_reg". Then it will substitute "iphase_reg" for
iphase" which will convert the existing "iphase_reg" to
"iphase_reg_reg". This will be confusing and will not compile.
(End of WARNING)

To give you some idea how functions are specified, here is the
specification for @code(snd-prod), which generates over 250 lines of C code:
@begin(example)
(PROD-ALG
  (NAME "prod")
  (ARGUMENTS ("sound_type" "s1") ("sound_type" "s2"))
  (START (MAX s1 s2))
  (COMMUTATIVE (s1 s2))
  (INNER-LOOP "output = s1 * s2")
  (LINEAR s1 s2)
  (TERMINATE (MIN s1 s2))
  (LOGICAL-STOP (MIN s1 s2))
)
@end(example)
A @code(.alg) file is always of the form:
@begin(example)
(@i(name)
  (@i(attribute) @i(value))
  (@i(attribute) @i(value))
  ...
)
@end(example)
There should be just one of these algorithms descriptions per file.
The @i(name) field is arbitrary: it is a Lisp symbol whose property list is
used to save the following attribute/value pairs.  There are many
attributes described below. For more examples, see the @code(.alg) files in
the @code(trnsrc) directory.

Understanding what the attributes do is not
easy, so here are three recommendations for implementors.  First, if there is
an existing Nyquist operator that is structurally similar to something you
want to implement, make a copy of the corresponding @code(.alg) file and
work from there. In some cases, you can merely rename the parameters and
substitute a new inner loop.  Second, read the generated code, especially
the generated inner loop.  It may not all make sense, but sometimes you can
spot obvious errors and work your way back to the error in the @code(.alg)
file.  Third, if you know where something bad is generated, see if you can 
find where the code is generated.  (The code generator files are listed in
@code(init.lsp).)  This code is poorly written and poorly documented, but in
some cases it is fairly straightforward to determine what attribute in the
@code(.alg) file is responsible for the erroneous output.

@section(Attributes)
Here are the attributes used for code generation. Attributes and values may
be specified in any order.
@begin(description)
@code[(NAME "@i(string)")]@\specifies a base name for many identifiers.  In
particular, the generated filenames will be @i(string)@code(.c) and
@i(string)@code(.h), and the XLisp function generated will be
@code(snd-)@i(string).

@code[(ARGUMENTS @i(arglist))]@\describes the arguments to be passed from
XLisp. @i(Arglist) has the form: @code[(@i(type1) @i(name1)) (@i(type2)
@i(name2)) ...], where @i(type) and @i(name) are strings in double quotes,
e.g. ("sound_type" "s") specifies a SOUND parameter named @code(s).  Note that @i(arglist) is not surrounded by parentheses.  As seen
in this example, the type names and parameter names are C identifiers. Since
the parameters are passed in from XLisp, they must be chosen from a
restricted set.  Valid type names are: @code("sound_type"), @code("rate_type"), @code("double"),
@code("long"), @code("string"), and @code("LVAL").


@code[(STATE @i(statelist))]@\describes additional state (variables) needed
to perform the computation.  A @i(statelist) is similar to an @i(arglist)
(see @code(ARGUMENTS) above), and has the form: @code{(@i(type1) @i(name1)
@i(init1) [TEMP]) (@i(type2) @i(name2) @i(init2) [TEMP]) ...}. 
The types and names are as
in @i(arglist), and the "inits" are double-quoted initial values.  Initial
values may be any C expression.  State is initialized in the order implied by 
@i(statelist) when the operation is first called from XLisp.  If @code(TEMP)
is omitted the state is preserved in a structure until the sound computation
completes.  Otherwise, the state variable only exists at state
initialization time.

@code[(INNER-LOOP @i(innerloop-code))]@\describes the inner loop, written as
C code. The @i(innerloop-code) is in double quotes, and may extend over
multiple lines.  To make generated code extra-beautiful, prefix each line of
@i(innerloop-code) with 12 spaces.  Temporary variables should not
be declared at the beginning of @i(innerloop-code). Use the
@code(INNER-LOOP-LOCALS) attribute instead.  Within @i(innerloop-code),
@i(each ARGUMENT of type sound_type) @p(must) @i(be referenced exactly one
time.) If you need to use a signal value twice, assign it once to a
temporary and use the temporary twice.  The inner loop must also assign
@i(one) time to the psuedo-variable @i(output).  The model here is that the
name of a sound argument denotes the value of the corresponding signal at
the current output sample time.  The inner loop code will be called once for
each output sample.  In practice, the code generator will substitute some
expression for each signal name. For example,
@code(prod.alg) specifies
@display[@code[(INNER-LOOP "output = s1 * s2")]]
(@code(s1) and @code(s2) are @code(ARGUMENTS).)  This expands to the
following inner loop in @code(prod.c):
@display[@code[*out_ptr_reg++ = *s1_ptr_reg++ * *s2_ptr_reg++;]]
In cases where arguments have different sample rates, sample interpolation
is in-lined, and the expressions can get very complex. The translator is
currently very simple-minded about substituting access code in the place of
parameter names, and @i(this is a frequent source of bugs.)  Simple string
substitution is performed, so @i(you must not use a parameter or state name
that is a substring of another).  For example, if two sound parameters were
named @code(s) and @code(s2), the translator might substitute for ``s'' in two
places rather than one.  If this problem occurs, you will almost certainly
get a C compiler syntax error.  The fix is to use ``more unique'' parameter
and state variable names.

@code[(INNER-LOOP-LOCALS "@i(innerloop-code)")]@\The @i(innerloop-code)
contains C declarations of local variables set and referenced in the inner
loop.

@code[(SAMPLE-RATE "@i(expr)")]@\specifies the output sample rate; @i(expr)
can be any C expression, including a parameter from the @code(ARGUMENTS)
list. You can also write @code[(SAMPLE-RATE (MAX @i(name1) @i(name2) ...))]
where names are unquoted names of arguments.

@code[(SUPPORT-HEADER "@i(c-code)")]@\specifies arbitrary C code to be
inserted in the generated @code(.h) file. The code typically contains
auxiliarly function declarations and definitions of constants.

@code[(SUPPORT-FUNCTIONS "@i(c-code)")]@\specifies arbitrary C code to be
inserted in the generated @code(.c) file. The code typically contains
auxiliarly functions and definitions of constants.

@code[(FINALIZATION "@i(c-code)")]@\specifies code to execute when the sound
has been fully computed and the state variables are about to be
decallocated.  This is the place to deallocate buffer memory, etc.

@code[(CONSTANT "@i(name1)" "@i(name2)" ...)]@\specifies state variables that
do not change value in the inner loop.  The values of state
variables are loaded into registers before entering the inner loop so that
access will be fast within the loop.  On exiting the inner loop, the final
register values are preserved in a ``suspension'' structure.  If state
values do not change in the inner loop, this @code(CONSTANT) declaration can
eliminate the overhead of storing these registers.

@code[(START @i(spec))]@\specifies when the output sound should start (a
sound is zero and no processing is done before the start time). The @i(spec)
can take several forms: @code[(MIN @i(name1) @i(name2) ...)] means the start
time is the minimum of the start times of input signals @i(name1),
@i(name2), ....  Note that these names are not quoted.

@code[(TERMINATE @i(spec))]@\specifies when the output
sound terminates (a sound is
zero after this termination time and no more samples are computed).  The
@i(spec) can take several forms: @code[(MIN @i(name1) @i(name2) ...)] means
the terminate time is the minimum of the terminate times of input arguments
@i(name1), @i(name2), ....  Note that these names are not quoted.  To
terminate at the time of a single argument @code(s1), specify @code[(MIN
s1)].  To terminate after a specific duration, use @code[(AFTER "@i(c-expr)")],
where @i(c-expr) is a C variable or expression.  To terminate at a
particular time, use @code[(AT "@i(c-expr)")].  @i(spec) may also be
@code(COMPUTED), which means to use the maximum sample rate of any input
signal.

@code[(LOGICAL-STOP @i(spec))]@\specifies the logical stop time of the output
sound.  This @i(spec) is just like the one for @code(TERMINATE).  If no
@code(LOGICAL-STOP) attribute is present, the logical stop will coincide
with the terminate time.

@code[(ALWAYS-SCALE @i(name1) @i(name2) ...)]@\says that the named sound
arguments (not in quotes) should always be multiplied by a scale factor.
This is a space-time tradeoff. When Nyquist sounds are scaled, the scale
factor is merely stored in a structure.  It is the responsibility of
the user of the samples to actually scale them (unless the scale factor is
exactly 1.0).  The default is to generate code with and without scaling and
to select the appropriate code at run time.  If there are N signal inputs,
this will generate 2@+(N) versions of the code.  To avoid this code
explosion, use the @code(ALWAYS-SCALE) attribute.

@code[(INLINE-INTERPOLATION @i(flag))]@\controls when sample rate interpolation
should be performed in-line in the inner loop. There are two forms of sample
rate interpolation.  One is intended for use when the rate change is large
and many points will be interpolated.  This form uses a divide instruction
and some setup at the low sample rate, 
but the inner loop overhead is just an add. The
other form, intended for less drastic sample rate changes, performs
interpolation with 2 multiplies and several adds per sample at the high
sample rate.  If inline interpolation is enabled, Nyquist generates various 
inner loops and selects the appropriate one at run-time. (This can cause a
combinatorial explosion if there are multiple sound arguments.) If inline
interpolation is not enabled, much less code is generated and interpolation
is performed as necessary
by instantiating a separate signal processing operation. The value of @i(flag)
is @code(YES) to generate inline interpolation, @code(NO) to disable
inline interpolation, and @code(NIL) to take the default set by the 
global variable @code(*INLINE-INTERPOLATION*). The default is also taken
if no @i(INLINE-INTERPOLATION) attribute is specified.


@code[(STEP-FUNCTION @i(name1) @i(name2) ...)]@\Normally all argument 
signals are
linearly interpolated to the output sample rate.  The linear interpolation
can be turned off with this attribute. This is used, for example, in Nyquist
variable filters so that filter coefficients are computed at low sample
rates.  In fact, this attribute was added for the special case of filters.

@code[(DEPENDS @i(spec1) @i(spec2) ...)]@\Specifies dependencies.  This
attribute was also introduced to handle the case of filter coefficients (but
may have other applications.)  Use it when a state variable is a function of
a potentially low-sample-rate input where the input is in the
@code(STEP-FUNCTION) list.  Consider a filter coefficient that depends upon
an input signal such as bandwidth.  In this case, you want to compute the
filter coefficient only when the input signal changes rather than every
output sample, since output may occur at a much higher sample rate.  A
@i(spec) is of the form 
@display{@code{("@i(name)" "@i(arg)" "@i(expr)" [TEMP @i("type")])}}
which is interpreted as follows: @I(name) depends upon @i(arg); when @i(arg)
changes, recompute @i(expr) and assign it to @i(name). The @i(name) must be
declared as a @code(STATE) variable unless @code(TEMP) is present, in which
case @i(name) is not preserved and is used only to compute other state.
Variables are updated in the order of the @code(DEPENDS) list.

@code[(FORCE-INTO-REGISTER @i(name1) @i(name2) ...)]@\causes @i(name1),
@i(name2), ... to be loaded into registers before entering the inner loop.
If the inner loop references a state variable or argument, this happens
automatically. Use this attribute only if references are ``hidden'' in a
@code(#define)'d macro or referenced in a @code(DEPENDS) specification. 

@code[(NOT-REGISTER @i(name1) @i(name2) ...)]@\specifies state and arguments
that should not be loaded into registers before entering an inner loop.
This is sometimes an optimization for infrequently accessed state.

@code[(NOT-IN-INNER-LOOP "@i(name1)" "@i(name2)" ...)]@\says that certain
arguments are not used in the inner loop.  Nyquist assumes all arguments
are used in the inner loop, so specify them here if not.  For example,
tables are passed into functions as sounds, but these sounds are not read
sample-by-sample in the inner loop, so they should be listed here.

@code[(MAINTAIN ("@i(name1)" "@i(expr1)") ("@i(name2)" "@i(expr2)") ...
)]@\Sometimes the IBM XLC compiler generates better loop code if a variable
referenced in the loop is not referenced outside of the loop after the loop
exit.  Technically, optimization is better when variables are dead upon loop
exit. Sometimes, there is an efficient way to compute the final value of a
state variable without actually referencing it, in which case the variable
and the computation method are given as a pair in the @code(MAINTAIN)
attribute.  This suppresses a store of the value of the named variable,
making it a dead variable.  Where the store would have been, the expression
is computed and assigned to the named variable.  See @code(partial.alg) for
an example.  This optimization is never necessary and is only for
fine-tuning.

@code[(LINEAR @i(name1) @i(name2) ...)]@\specifies that named arguments
(without quotes) are linear with respect to the output.  What this
@i(really) means is that it is numerically OK to eliminate a scale factor from
the named argument and store it in the output sound descriptor, avoiding a
potential multiply in this inner loop.  For example, both arguments to
@code(snd-prod) (signal multiplication) are ``linear.''  The inner loop has
a single multiplication operator to multiply samples vs. a potential 3
multiplies if each sample were also scaled.  To handle scale factors on the
input signals, the scale factors are automatically multiplied and the
product becomes the scale factor of the resulting output.  (This effectively
``passes the buck'' to some other, or perhaps more than one,  signal
processing function, which is not always optimal. On the other hand, it
works great if you multiply a number of scaled signals together: all the
scale factors are ultimately handled with a single multiply.)

@code[(INTERNAL-SCALING @i(name1) @i(name2) ...)]@\indicates that scaling is
handled in code that is hidden from the code generator for @i(name1),
@i(name2), ..., which are sound arguments. Although it is the responsibility
of the reader of samples to apply any given scale factor, sometimes scaling
can be had for free.  For example, the @code(snd-recip) operation computes
the reciprocal of the input samples by peforming a division.  The simple
approach would be to specify an inner loop of @code[output = 1.0/s1], where
@code(s1) is the input.  With scaling, this would generate an inner loop
something like this:
@display(@code[*output++ = 1.0 / (s1_scale_factor * *s1++);])
but a much better approach would be the following:
@display(@code[*output++ = my_scale_factor / *s1++])
where @code(my_scale_factor) is initialized to @code(1.0 / s1->scale).
Working backward from the desired inner loop to the @code(.alg) inner loop
specification, a first attempt might be to specify:
@display(@code[(INNER-LOOP "output = my_scale_factor / s1")])
but this will generate the following:
@display(@code[*output++=my_scale_factor/(s1_scale_factor * *s1++);])
Since the code generator does not know that scaling is handled elsewhere,
the scaling is done twice!  The solution is to put @code(s1) in the
@code(INTERNAL-SCALING) list, which essentially means ``I've already
incorporated scaling into the algorithm, so suppress the multiplication by a
scale factor.''

@code[(COMMUTATIVE (@i(name1) @i(name2) ...))]@\specifies that the results
will not be affected by interchanging any of the listed arguments.  When
arguments are commutative, Nyquist rearranges them at run-time into
decreasing order of sample rates.  If interpolation is in-line, this can
dramatically reduce the amount of code generated to handle all the different
cases.  The prime example is @code(prod.alg).

@code[(TYPE-CHECK "@i(code)")]@\specifies checking code to be inserted after
argument type checking at initialization time. See @code(downproto.alg) for
an example where a check is made to guarantee that the output sample rate is
not greater than the input sample rate.  Otherwise an error is raised.

@end(description)

@section(Generated Names)
The resulting @code(.c) file defines a number of procedures. The procedures
that do actual sample computation are named something like
@i(name)@c(_)@i(interp-spec)@c(_fetch), where @i(name) is the @c(NAME)
attribute from the @code(.alg) file, and @i(interp-spec) is an interpolation
specification composed of a string of the following letters: n, s, i, and r.
One letter corresponds to each sound argument, indicating no interpolation
(r), scaling only (s), ordinary linear interpolation with scaling (i), and
ramp (incremental) interpolation with scaling (r).  The code generator
determines all the combinations of n, s, i, and r that are necessary and
generates a separate fetch function for each.

Another function is @i(name)@code(_toss_fetch), which is called when sounds
are not time-aligned and some initial samples must be discarded from one or
more inputs.

The function that creates a sound is @code(snd_make_)@i(name).  This is
where state allocation and initialization takes place.  The proper fetch
function is selected based on the sample rates and scale factors of the
sound arguments, and a @code(sound_type) is returned.

Since Nyquist is a functional language, sound operations are not normally allowed to
modify their arguments through side effects, but even reading samples from a
@code(sound_type) causes side effects. To hide these from the Nyquist
programmer, @code(sound_type) arguments are first copied (this only copies a small structure. The samples themselves are on a shared list). The function
@code(snd_)@i(name) performs the necessary copies and calls
@code(snd_make_)@i(name).  It is the @code(snd_)@i(name) function that is
called by XLisp.  The XLisp name for the function is @code(SND-)@i(NAME).
Notice that the underscore in C is converted to a dash in XLisp.  Also,
XLisp converts identifiers to upper case when they are read, so normally,
you would type @code(snd)-@i(name) to call the function.

@section(Scalar Arguments)
If you want the option of passing either a number (scalar) or a signal as
one of the arguments, you have two choices, neither of which is automated.
Choice 1 is to coerce the constant into a signal from within XLisp.  The
naming convention would be to @code(DEFUN) a new function named
@i(NAME) or @code(S-)@i(NAME) for ordinary use.  The @i(NAME) function tests
the arguments using XLisp functions such as @code(TYPE-OF), @code(NUMBERP),
and @code(SOUNDP).  Any number is converted to a @code(SOUND), e.g. using
@code(CONST).  Then @code(SND-)@i(NAME) is called with all sound arguments.
The disadvantage of this scheme is that scalars are expanded into a sample
stream, which is slower than having a special inner loop where the scalar
is simply kept in a register, avoiding loads, stores, and addressing
overhead.

Choice 2 is to generate a different sound operator for each case.  The
naming convention here is to append a string of c's and v's, indicating
constant (scalar) or variable (signal) inputs.  For example, the
@code(reson) operator comes in four variations: @code(reson),
@code(resoncv), @code(resonvc), and @code(resonvv).  The @code(resonvc)
version implements a resonating filter with a variable center frequency (a
sound type) and a constant bandwidth (a @code(FLONUM)).  The @code(RESON)
function in Nyquist is an ordinary Lisp function that checks types and calls
one of @code(SND-RESON), @code(SND-RESONCV), @code(SND-RESONVC), or
@code(SND-RESONVV).  

Since each of these @code(SND-) functions performs further selection of
implementation based on sample rates and the need for scaling, there are 25
different functions for computing RESON!  So far, however, Nyquist is
smaller than Common Lisp and it's about half the size of Microsoft Word.
Hopefully, exponential growth in memory density will outpace linear (as a
function of programming effort) growth of Nyquist.

