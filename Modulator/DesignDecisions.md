
# Design Decisions for this application

## APRSPacket

- Immutable, created with an APRSPacketBuilder to make parameter entry easier.
- For smaller memory footprint of packet, info is stored as arrays of Uint8
- Rehydratable into a contiguous string of bits, unstuffed

## APRSListener

- Gets +/- samples from a Sampler
    - Queue of Bools
    
- Decodes NRZI to simple 1s and 0s
- Finds flag locations
    - Start out with empty packet
    - Starts in search state, looking to see if we can find 1111110 (first 0 might have been curtailed)
    - Once a flag is found, we go into packet search mode and dequeue the flag bits
        - If we find another flag, just dequeue it again
        - Keep putting bools on the output packet as long as we don't see 6 ones in a row (vectorize this?)
        - Once we see 6 ones in a row, then a zero, we know it's a flag and can cut off the end of the packet
        - Put packet into output queue if it is greater in length than 152 bytes, or shorter than 3168 bytes.
        - go back into search mode 
- Dumps de-stuffed bytes from between successive flags (if they are >= 19 bytes between flags) into the APRSPacket. which will separate the packet fields and compute the CRC. If the packet is not valid, then nil will be returned. 

- Might want to change PLL adjustment rate when locked on to a flag?
- Ideally can detect APRS packets that have only a single flag in front of them. 
    - See how many flags are required for detection at different PLL adjustment rates
    - Smaller alpha - faster lock on - More sampling jitter which is ultimately bad but if there aren't enough flags then it's unlit

'


## Concurrency and Processing Chain
- An AudioDispatcher takes in an AudioProcessOperationFactory and dumps Float samples (converted from SInt16) into an AudioProcessOperation's inputSamples. It then sends it off to work in an OperationQueue. The completion of the operation will append a decoded APRSPacket to a settable queue. 


### Considerations for queue based semi-automatic blocks
- Like gnu radio, can have synchronous (1:1), decimator (N:1), interpolator(1:M), and general (N:M), or completely nondeterministic (?:?) blocks. Queues will most likely connect these together but we want to ensure performance
    - To support nondeterministic blocks, need to use queues to ensure those blocks and pick off and put on to their input and output queues (respectively) at their own whatever rate
    - If we use vectorized operations on these queues, copying memory could be kind of expensive which we will almost surely have to do unless the signal comes in significantly sized chunks that are big enough that we can do vectorized operations on each without a lot of overhead (might be the way to go here)
    - Synchronous blocks are probably the easiest case, can just wait until queue has a large enough amount of items in it (and enforce that chunks of a certain size are contiguous in memory just wrap around) and just vector process the entire thing since it's 1:1
    - Decimator blocks that need to put out chunks of a certain size must wait until the queue has a chunk of N times that size before processing (could result in lots of data accumulating, and resizing/copying if queue was not allocated to be large enough).
    - Interpolator is going to dump a lot of data at once

- This seems like a little too much for this app, but creating a framework with blocks that do this in a swift style is something I may want to look into in the future.

# Future Applications/Frameworks where thigns from this project may be used
- 


# UI

Receive view should show full-screenable map, possible indicators N/S/E/W to show that other packets have been registered in areas of the map not shown.

Allow sliding (or just full map, half map, and no map) views, the other part being the received packet list

Settable filtering of packets on map and in list
- Only show packets recieved in the last x amount of time
- Only show packets from callign x
- (In list only) only show packets that are not location updates
- Only show mic-e encoded data
- Collapse digipeated packets
- 

Might want to redesign APRSPacket Class to allow easier filtering in this way
- Core data/ database style filter
- 







