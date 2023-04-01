## 2015-02-26: An idea about 'type classes'

Type classes indicate how data values can be used, but not what they mean.

E.g. a URL and the contents of a file might both be represented by a
List[Byte], but have very different meanings.  Roles are used to
distinguish those.  This is kind of analogous to how in some
languages, a float and an int might both be representable using the
same 32-bit value, but those bits have very different meanings,
and which type a function parameter has can
determine which overloaded version of the function is called.

Now let's say in our hypothetical system...

The way in which a type class implments a role is also indicated
separately from either.  E.g. if we want to treat a PHP array as a
function, there are a couple of obvious interpretations:
- as a [someObject, methodName] callback, as per PHP `callable` convention (`myArray(foo)` calls the method)
- as a function of its keys to its values (`myArray(0)` returns `someObject`)

In the following, '<' means 'can be used as'.

All values are 'resources'.  A resource may be identified by its
value, by a URN, and/or by the expression that resolves to it.  Which
representation is used internally is up to the compiler.

Function1[ArgumentType,ReturnValueType]

Collection[KeyType,ValueType] < Function1[KeyType,ValueType]
- An ordered list of key=>values
- Entries can be iterated over or queried by key
- Can be queried for number of entries
- map( Function1[V1,V2], Collection[K,V1] ) -> Collection[K,V2]

List[ValueType] < Collection[Integer,ValueType]
- Can be sliced

List[Byte]
- A sequence of bytes

Array[ValueType,numberOfDimensions]
- N-dimensional positionally-keyed collection of ValueType.
- Array[ValueType,4](Integer,Integer,Integer,Integer) -> ValueType

Array[ValueType,1] < Collection[Integer,ValueType]

Float < Number
Float64 < Float
Float32 < Float
Rational < Number
Integer < Rational
Int32 < Integer
UInt8 < Integer

2D Image
- width
- height
- slice( 2D Image, x0, y0, x1, y1 ) -> 2D Image
- scale( 2D Image, xFactor, yFactor ) -> 2D Image
- get HDR data ( Image, channel name ) -> Array[Number, 2]
- get LDR data ( Image, channel name ) -> Array[UInt8, 2]
- construct image from HDR data ( Collection[channel name, Array[Number,2]] ) -> 2D Image
- construct image from LDR data ( Collection[channel name, Array[Number,2]] ) -> 2D Image (numbers are clamped between 0-255)


## 2023-03-03: Thoughts on representing values encoded by data

See also: [Datatypes](../DATATYPES.org) and the `http://ns.nuke24.net/TOGVM/Expression/DataInterpretation` expression.

See also: Thoughts from Ben's basement, 2023-01-30:

> Thoughts on simplified value representation in TDAR: :tdar:lisp:
> - Any value can be represented by (data, list of applied encodings)
>   - Encoding list should be in reverse order, i.e. outermost encoding first;
>     this makes things work out nicely with linked lists.
> - A 'simplified' value simply places restrictions on what encodings are allowed
> - Could do like (value . encodings) so that it looks like a single list;
>   this is cute but might be problematic if I ever want to include other information
>   in the structure.  Better to do (value . (encoding-list . nil)).

See also: http://ns.nuke24.net/TScript34/Op/PushValue, as defined in
[TScript34/P0002](https://github.com/TOGoS/TScript34/blob/84ec9a09f5e8685c96debdee7119afb2e5373a7a/P0002/Interpreter.cs).


Thought: It would be nice if, for some purposes, e.g.
internal representation of resources in TDAR, or in TScript34,
or other TOGVM-related systems, there was a unified system
for representing any value, even if decoding or other abstract
method of decoding is required.

Examples of such values:
- The person named 'Dan'
- The resouce named by the URI "urn:bitprint:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ.NLB3V6CWMBDLEWGFJDOMFXQNS3FXYR6F25HK3MI"
- The two-channel waveform encoded by the file urn:bitprint:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ.NLB3V6CWMBDLEWGFJDOMFXQNS3FXYR6F25HK3MI
  (note that this is simply an additional decoding/interpretation step beyond the previous example)
- The 2-dimensinal heightmap encoded by the RGB channels of a PNG file
  (as used by https://docs.mapbox.com/data/tilesets/reference/mapbox-terrain-dem-v1/)

Would-be-nice features:
- Though 'decoding' is the main problem to be solved, it would be great
  if the scheme could be easily reversed to represent values
  encoded by those same datatypes.

### The TScript34/Op/PushValue scheme

http://ns.nuke24.net/TScript34/Op/PushValue takes as arguments:
- the encoded value
- datatypes corresponding to each decode step to be applied, n the order that they would be applied to decode the value.

This is kind of nice since it can be thought of as a pipeline
(`encoded-value | decode1 | decode2 | ... | decodeN`)
or as a program in RPN.

Either way there is a minor conceptual translation that must be done:
- The first argument represents data, while the remaining arguments represent decode steps.
- The remaining arguments are datatypes, not decoding functions.
  To translate to a pipeline, 'decoder for this datatype' is implied for each one.

### Pipeline format

Note that we don't necessarily want to "just write it as a list of decode operations",
since the whole point is to pass around a data structure representing the decoded value
in terms of its encoded form without having to actually do the decoding!

That said, if we did want to use the same language,
we could write the expression representing the decoded value like this:

`"urn:sha1:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ" uri-to-resource audio-file-to-mcas-content`

and to go the other way:

(some expression resulting in an MCAS) + ` mcas-to-flac store-file-and-return-sha1-urn`.

In this case the encoding step seems to have more options--what format
to encode as, how to store, what URI scheme to use--so maybe it doesn't make
so much sense to worry about symmetry.

### TS34Encoded Datatype

Note: These notes are accurate but use a deprecated name.
See http://www.nuke24.net/docs/2023/TS34EncodedDatatype.html for canonical documentation
about this datatype.

`http://ns.nuke24.net/TOGVM/Datatypes/TS34Encoded` names a datatype,
which is documented in [DATATYPES.org](../DATATYPES.org).

Basically, the lexical format is the URI of some encoded data,
followed by a list of datatypes that have been applied to it,
outermost-to-innermost, i.e. such that decoding the data
by each datatype in order results in the value in question.

This string happens to be identical to `http://ns.nuke24.net/TScript34/Op/PushValue`s argument list.

For practical purposes, I would also like to use this same URI
for JavaScript objects.

#### Use as a tag for JSON-encoded objects

An example JSON-encoded data structure representing such an encoded value might look like this:

```json
{
	"classRef": "http://ns.nuke24.net/TOGVM/Datatypes/TS34Encoded",
	"data": "urn:sha1:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ",
	"datatypeRefs": [
		"http://ns.nuke24.net/TOGVM/Datatypes/URIResource",
		"http://ns.nuke24.net/SynthGen2100/P0025/Datatypes/MCAS"
	]
}
```

Or one of various unambiguous alternate representations
where 'data' is referenced by a URI and there is only a single datatype:

```json
{
	"classRef": "http://ns.nuke24.net/TOGVM/Datatypes/TS34Encoded",
	"dataRef": "urn:sha1:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ",
	"datatypeRef": "http://ns.nuke24.net/SynthGen2100/P0025/Datatypes/MCAS"
}
```

For internal JavaScript applications, especially ones in which even this
could be ambiguous (maybe this literal JavaScript object is intended),
the Synx schema symbol (`Symbol.for("http://ns.nuke24.net/Synx/schema")`) could be used:

```javascript
{
	[Symbol.for("http://ns.nuke24.net/Synx/schema")]: "http://ns.nuke24.net/TOGVM/Datatypes/TS34Encoded",
	"data": "urn:sha1:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ",
	"datatypeRefs": [
		"http://ns.nuke24.net/TOGVM/Datatypes/URIResource",
		"http://ns.nuke24.net/SynthGen2100/P0025/Datatypes/MCAS"
	]
}
```

If you really have to cram that into JSON in a place where interpretation would otherwise be ambiguous,
maybe use an "@" prefix, following JSON-LDs lead: `{ "@http://ns.nuke24.net/Synx/schema": ... }`;
but that said, a simpler alternative is to use this format which is *actually* valid JSON-LD,
but uses the stringified format:

```json
{
	"@type": "http://ns.nuke24.net/TOGVM/Datatypes/TS34Encoded",
	"@value": "urn:sha1:M6C265JRWGZO5Q7NJMTQ7QHHGUSEX5IJ http://ns.nuke24.net/SynthGen2100/P0025/Datatypes/MCAS"
}
```

Note that `"@type"` in JSON-LD means different things based on context;
the datatype used to encode a simple value, as above, means [lexical-to-value mapping of the `@value`](https://www.w3.org/TR/json-ld/#typed-values),
whereas in other contexts (when `@value` isn't specified?  Not sure.) it's actually an attribute
of the object being described; i.e. in the non-litertal context is is data, rather than metadata.
People [have argued](https://github.com/json-ld/json-ld.org/issues/103) about whether there should be
a separate `@datatype` or `@valuetype` attribute (I don't entirely understand the decision not to).

That said, I generally think of `classRef` as being synonymous with `@type`,
but without the connotation that the data structure makes sense as JSON-LD.
Since `TS34Encoded` is a datatype, not a class with instances*,
its use as a the class of a given data structure should be relatively unambiguous.
"No, I'm not describing an instance of TS34Encoded; I'm giving you the TS34Encoded representation
of the object, and you should understand that by this I mean the object that you'd
get by applying the decoding steps!"
