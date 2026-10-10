# Atlas network library

Load one node file and its matching edge file. Each edge matrix uses the same
row order as its paired node file. Coordinates and numeric values are supplied
in the files; selecting a display surface does not establish registration.

| Family | Nodes | Node file | Edge file(s) |
| --- | ---: | --- | --- |
| AAL90 | 90 | AAL90.node | AAL90_Binary.edge; AAL90_Weighted.edge |
| AAL3v2 | 166 | AAL3v2_GroupFC.node | AAL3v2_GroupFC.edge |
| Brodmann82 | 82 | Brodmann82.node | Brodmann82.edge |
| Dos160 | 160 | Dos160.node | Dos160_Binary.edge; Dos160_Weighted.edge |
| Fair34 | 34 | Fair34.node | Fair34_Binary.edge; Fair34_Weighted.edge |
| HOA112 | 112 | HOA112.node | HOA112_Binary.edge; HOA112_Weighted.edge |
| Glasser360 | 360 | Glasser360_GroupFC.node | Glasser360_GroupFC.edge |
| Power264 | 264 | Power264_GroupFC.node | Power264_GroupFC.edge |
| Shen278 | 278 | Shen278_GroupFC.node | Shen278_GroupFC.edge |
| Schaefer100Yeo7 | 100 | Schaefer100Yeo7_GroupFC.node | Schaefer100Yeo7_GroupFC.edge |
| Schaefer200Yeo7 | 200 | Schaefer200Yeo7_GroupFC.node | Schaefer200Yeo7_GroupFC.edge |
| Schaefer400Yeo7 | 400 | Schaefer400Yeo7_GroupFC.node | Schaefer400Yeo7_GroupFC.edge |

`AAL116.node` contains 116 nodes without a matching edge file. Do not pair it
with AAL90 matrices. `../FormatExamples/ROI.node` is a six-node format example.

The seven `GroupFC` matrices were generated from resting-state fMRI data from a
group of adult healthy participants. Their node values represent connection
strength and their module fields represent network assignments. These files
are visualization examples, not normative connectivity estimates. Other files
retain their supplied module and value fields; these fields must not be assumed
to be Yeo assignments or the same connectivity measure as the GroupFC examples.

Source links for the GroupFC atlas families are in the accompanying
`NOTICE_ATLAS_NETWORK_EXAMPLES.md`. Family-specific `*_Reference.txt` files
provide citations for AAL90, Brodmann82, Dos160, Fair34 and HOA112.

The AAL90 volume, vertex labels, masks and boundary examples are in `../AAL90/`.
Volume labels and surface labels require the corresponding coordinate frame
and vertex order. `Cover.mat` is a configuration example, not an edge matrix.
