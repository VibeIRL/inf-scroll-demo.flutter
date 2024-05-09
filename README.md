# inf_scroll_demo

 The ansynchronous dummy input sources used in this app are:

 1. Hive LazyBox
 2. WebSocketChannel (using the echo server)
 3. Simulated polling

 All data is string data, though the Hive box is populated
 with ints, and string representations of ints are used for
 the WebSocketChannel - ints are just easier to generate then
 random strings and look nicer. The data used for the
 simulated polling is just the string 'BREAKING NEWS'.

 In (1), the box is populated initially with ints [0, 499], then
 repopulated every time it's found to be empty. In (2), string
 representations of random ints are generated at random intervals
 and sent through the channel, which simply echos them back in a
 stream - a subscriber accumulating them into a list which is
 emptied whenever its elements are used. (3) is similar, with the
 'BREAKING NEWS' string being generated at random intervals and
 a subscriber accumulating them in a list.

