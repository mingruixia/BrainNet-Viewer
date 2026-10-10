# Network example files

`Data/ExampleFiles/AtlasNetworks` contains node/edge examples arranged by atlas.
Use the accompanying README to choose a matched pair and find its region count.
The updated GroupFC pairs are group-level resting-state connectivity examples
from healthy adults; node sizes represent connection strength and node colors
represent network modules. Atlas sources and citations are listed in
`NOTICE_ATLAS_NETWORK_EXAMPLES.md` and the accompanying reference files.

AAL90, Brodmann82, Dos160, Fair34 and HOA112 supply additional format/network
examples. Do not describe their edge weights as the updated GroupFC matrices.
The standalone AAL116 node table has no matching bundled 116-by-116 edge matrix.
Boundary/vertex maps require their corresponding surface vertex order.
`Data/ExampleFiles/AAL90` retains the AAL volume, vertex labels, masks and
configuration support files. Its AAL IDs differ from AAL3v2.

The six-node file in `Data/ExampleFiles/FormatExamples` illustrates the node
format and is not a measured connectivity dataset. Successful loading does
not establish coordinate alignment or statistical validity.
